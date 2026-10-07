# Account creation layer. Run with credentials for the organization management
# (payer) account in the COMMERCIAL partition.
#
# partition = "aws-us-gov" (default): replaces the commercial CDK stack
# (source/lib/compliant-framework-stack.ts): every request creates a commercial
# "twin" account plus a standalone GovCloud account (CreateGovCloudAccount),
# which 02-organization then invites into the GovCloud organization. The
# Account Vending Machine can optionally be deployed.
#
# partition = "aws": accounts are created directly in the commercial
# organization (CreateAccount); 02-organization manages the same organization
# and places them in their OUs.

locals {
  config = yamldecode(file(coalesce(var.config_file, "${path.root}/../../config/framework.yaml")))

  is_govcloud         = try(local.config.partition, "aws-us-gov") == "aws-us-gov"
  commercial          = local.config.commercial
  account_access_role = try(local.config.account_access_role_name, "CompliantFrameworkAccountAccessRole")
  accounts            = local.commercial.accounts

  # In commercial mode 02-organization owns the organization resource.
  create_organization = local.is_govcloud && try(local.commercial.create_organization, false)
  enable_avm          = try(local.commercial.account_vending_machine.enabled, false)
}

provider "aws" {
  region = local.commercial.region

  default_tags {
    tags = local.config.tags
  }
}

data "aws_partition" "current" {}

resource "terraform_data" "checks" {
  lifecycle {
    precondition {
      condition     = data.aws_partition.current.partition == "aws"
      error_message = "01-accounts must run with commercial-partition (aws) credentials for the organization management account; got ${data.aws_partition.current.partition}."
    }
    precondition {
      condition     = local.is_govcloud || !local.enable_avm
      error_message = "The Account Vending Machine creates GovCloud accounts; enable it only when partition is aws-us-gov."
    }
  }
}

#
# Organization (commercial)
#
resource "aws_organizations_organization" "this" {
  count = local.create_organization ? 1 : 0

  feature_set = "ALL"
}

data "aws_organizations_organization" "this" {
  depends_on = [aws_organizations_organization.this]
}

# Holds the commercial twins of the GovCloud accounts.
resource "aws_organizations_organizational_unit" "govcloud_accounts" {
  count = local.is_govcloud ? 1 : 0

  name      = "govcloud-accounts"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "this" {
  for_each = local.accounts

  name                       = "${each.value.environment}-${each.value.name}"
  email                      = each.value.email
  create_govcloud            = local.is_govcloud
  role_name                  = local.account_access_role
  iam_user_access_to_billing = "DENY"
  parent_id                  = local.is_govcloud ? aws_organizations_organizational_unit.govcloud_accounts[0].id : null
  close_on_deletion          = false

  lifecycle {
    # role_name/iam_user_access_to_billing are not returned by the
    # Organizations API. parent_id is managed by 02-organization in
    # commercial mode.
    ignore_changes  = [role_name, iam_user_access_to_billing, parent_id]
    prevent_destroy = true
  }
}

# Same parameter names the CreateAccounts Lambda wrote, for existing tooling.
resource "aws_ssm_parameter" "account_id" {
  for_each = local.accounts

  name  = "/compliant/framework/accounts/${each.value.environment}/${each.value.name}/aws/id"
  type  = "String"
  value = aws_organizations_account.this[each.key].id
}

resource "aws_ssm_parameter" "govcloud_account_id" {
  for_each = local.is_govcloud ? local.accounts : {}

  name  = "/compliant/framework/accounts/${each.value.environment}/${each.value.name}/aws-us-gov/id"
  type  = "String"
  value = aws_organizations_account.this[each.key].govcloud_id
}

#
# Account Vending Machine (Service Catalog product for self-service GovCloud
# account requests)
#
module "account_vending_machine" {
  source = "../../modules/account-vending-machine"
  count  = local.is_govcloud && local.enable_avm ? 1 : 0

  tags = local.config.tags
}
