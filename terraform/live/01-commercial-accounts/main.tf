# Replaces the commercial-partition CDK stack (source/lib/compliant-framework-stack.ts):
#   - Initialize Organization (commercial side)  -> aws_organizations_organizational_unit
#   - Create Accounts (CreateGovCloudAccount)     -> aws_organizations_account (create_govcloud)
#   - Account Vending Machine (Service Catalog)    -> module.account_vending_machine (optional)
# The GovCloud side (organization, invitations) lives in 02-govcloud-organization.
#
# Run with credentials for the COMMERCIAL organization management (payer)
# account that is enabled for AWS GovCloud (US).

locals {
  config = yamldecode(file(coalesce(var.config_file, "${path.root}/../../config/framework.yaml")))

  commercial          = local.config.commercial
  account_access_role = try(local.config.account_access_role_name, "CompliantFrameworkAccountAccessRole")
  govcloud_accounts   = local.commercial.govcloud_accounts
}

provider "aws" {
  region = local.commercial.region

  default_tags {
    tags = local.config.tags
  }
}

#
# Organization (commercial)
#
resource "aws_organizations_organization" "this" {
  count = try(local.commercial.create_organization, false) ? 1 : 0

  feature_set = "ALL"
}

data "aws_organizations_organization" "this" {
  depends_on = [aws_organizations_organization.this]
}

resource "aws_organizations_organizational_unit" "govcloud_accounts" {
  name      = "govcloud-accounts"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

#
# GovCloud accounts. Each request creates a commercial "twin" account (placed in
# the govcloud-accounts OU) and a standalone GovCloud account which
# 02-govcloud-organization then invites into the GovCloud organization.
#
resource "aws_organizations_account" "govcloud" {
  for_each = local.govcloud_accounts

  name                       = "${each.value.environment}-${each.value.name}"
  email                      = each.value.email
  create_govcloud            = true
  role_name                  = local.account_access_role
  iam_user_access_to_billing = "DENY"
  parent_id                  = aws_organizations_organizational_unit.govcloud_accounts.id
  close_on_deletion          = false

  lifecycle {
    # role_name/iam_user_access_to_billing are not returned by the
    # Organizations API, so changes to them cannot be reconciled.
    ignore_changes  = [role_name, iam_user_access_to_billing]
    prevent_destroy = true
  }
}

# Same parameter names the CreateAccounts Lambda wrote, for existing tooling.
resource "aws_ssm_parameter" "account_id" {
  for_each = local.govcloud_accounts

  name  = "/compliant/framework/accounts/${each.value.environment}/${each.value.name}/aws/id"
  type  = "String"
  value = aws_organizations_account.govcloud[each.key].id
}

resource "aws_ssm_parameter" "govcloud_account_id" {
  for_each = local.govcloud_accounts

  name  = "/compliant/framework/accounts/${each.value.environment}/${each.value.name}/aws-us-gov/id"
  type  = "String"
  value = aws_organizations_account.govcloud[each.key].govcloud_id
}

#
# Account Vending Machine (Service Catalog product for self-service GovCloud
# account requests)
#
module "account_vending_machine" {
  source = "../../modules/account-vending-machine"
  count  = try(local.commercial.account_vending_machine.enabled, false) ? 1 : 0

  tags = local.config.tags
}
