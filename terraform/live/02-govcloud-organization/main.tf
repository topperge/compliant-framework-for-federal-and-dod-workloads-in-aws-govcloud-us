# GovCloud organization layer (run in the GovCloud central/management account).
#
# Replaces:
#   - InitializeOrganization Lambda (GovCloud side) and InviteAccounts Lambda
#     (source/lambda/initialize_organization, source/lambda/invite_accounts)
#   - initialize_organizational_units pipeline Lambda (environment OUs)
#   - buildspec.yml `aws ram enable-sharing-with-aws-organization` and
#     `aws servicecatalog enable-aws-organizations-access`
#   - config.json "central.ssmParameters" written by the CDK app

locals {
  config = yamldecode(file(coalesce(var.config_file, "${path.root}/../../config/framework.yaml")))

  account_access_role = try(local.config.account_access_role_name, "CompliantFrameworkAccountAccessRole")
  region_short = {
    "us-gov-west-1" = "usgw1"
    "us-gov-east-1" = "usge1"
  }

  environments = local.config.environments

  # environment-usgw1-prod (or environment-usgw1 for the "default" environment)
  environment_ou_names = {
    for env, e in local.environments : env => (
      env == "default"
      ? "environment-${local.region_short[e.region]}"
      : "environment-${local.region_short[e.region]}-${env}"
    )
  }

  # account id => parent OU id
  memberships = merge(
    { (tostring(local.config.logging.account_id)) = aws_organizations_organizational_unit.core_accounts.id },
    merge([
      for env, e in local.environments : merge(
        {
          (tostring(e.transit.account_id))             = aws_organizations_organizational_unit.environment[env].id
          (tostring(e.management_services.account_id)) = aws_organizations_organizational_unit.environment[env].id
        },
        { for t in try(e.tenants, []) : tostring(t.account_id) => aws_organizations_organizational_unit.tenants[env].id },
      )
    ]...),
  )
}

provider "aws" {
  region = local.config.primary_region

  default_tags {
    tags = local.config.tags
  }
}

data "aws_caller_identity" "current" {}

#
# Organization. If the organization already exists, import it first:
#   terraform import 'aws_organizations_organization.this' <o-xxxxxxxxxx>
#
resource "aws_organizations_organization" "this" {
  feature_set                   = "ALL"
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
}

resource "aws_organizations_organizational_unit" "core_accounts" {
  name      = "core-accounts"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "environment" {
  for_each = local.environments

  name      = local.environment_ou_names[each.key]
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "tenants" {
  for_each = local.environments

  name      = "${local.environment_ou_names[each.key]}-tenants"
  parent_id = aws_organizations_organizational_unit.environment[each.key].id
}

#
# Invite (GovCloud accounts created via CreateGovCloudAccount are standalone)
# and place every framework account in its OU.
#
resource "terraform_data" "membership" {
  for_each = {
    for id, parent in local.memberships : id => parent
    if id != data.aws_caller_identity.current.account_id
  }

  triggers_replace = [each.key, each.value]

  provisioner "local-exec" {
    command = join(" ", [
      "python3", "${path.module}/../../scripts/govcloud_org_membership.py",
      "--account-id", each.key,
      "--parent-id", each.value,
      "--role-name", local.account_access_role,
      "--region", local.config.primary_region,
    ])
  }
}

#
# Organization-wide sharing used by the framework
#
resource "aws_ram_sharing_with_organization" "this" {
  depends_on = [aws_organizations_organization.this]
}

resource "aws_servicecatalog_organizations_access" "this" {
  enabled = true

  depends_on = [aws_organizations_organization.this]
}

#
# SSM parameters consumed by templates / Service Catalog products
#
resource "aws_ssm_parameter" "organization_id" {
  name  = "/compliant/framework/organization/id"
  type  = "String"
  value = aws_organizations_organization.this.id
}

resource "aws_ssm_parameter" "central" {
  for_each = merge(
    {
      "/compliant/framework/logging/account/id"                       = tostring(local.config.logging.account_id)
      "/compliant/framework/central/service-catalog/provider-name"    = try(local.config.central.service_catalog_provider_name, "Central Services")
      "/compliant/framework/central/service-catalog/access-role-name" = local.account_access_role
    },
    try(local.config.central.ssm_parameters, {}),
  )

  name  = each.key
  type  = "String"
  value = each.value
}
