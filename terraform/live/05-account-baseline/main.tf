# Account baseline layer: replaces the service-managed StackSets
# security-baseline-stackset-<region>, backup-services-stackset-<region> and
# <env>-federation-stackset-<region> that targeted the environment OU, plus
# the Security Hub member invitation of environment accounts.
#
# Applied once per member account (scripts/deploy.sh baselines loops over the
# accounts of each environment).

locals {
  config = yamldecode(file(coalesce(var.config_file, "${path.root}/../../config/framework.yaml")))

  account_access_role = try(local.config.account_access_role_name, "CompliantFrameworkAccountAccessRole")
  central_account_id  = tostring(local.config.central.account_id)
  env                 = local.config.environments[var.environment]
  baseline            = try(local.config.account_baseline, {})

  member_accounts = distinct(concat(
    [tostring(local.env.transit.account_id), tostring(local.env.management_services.account_id)],
    [for t in try(local.env.tenants, []) : tostring(t.account_id)],
  ))

  tags = merge(local.config.tags, { Environment = var.environment })
}

provider "aws" {
  region = local.env.region

  allowed_account_ids = [var.account_id]

  assume_role {
    role_arn     = "arn:${data.aws_partition.current.partition}:iam::${var.account_id}:role/${local.account_access_role}"
    session_name = "compliant-framework-terraform"
  }

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "central"
  region = local.env.region

  allowed_account_ids = [local.central_account_id]

  default_tags {
    tags = local.tags
  }
}

data "aws_partition" "current" {
  provider = aws.central
}

# Fails the plan when the account is not part of the environment. (No
# module-level depends_on on this: it would defer the modules' data sources and
# make their for_each keys unknown at plan time.)
resource "terraform_data" "account_check" {
  lifecycle {
    precondition {
      condition     = contains(local.member_accounts, var.account_id)
      error_message = "account_id ${var.account_id} is not a transit, management-services or tenant account of environment ${var.environment}."
    }
  }
}

module "security_baseline" {
  source = "../../modules/security-baseline"

  central_account_id             = local.central_account_id
  management_services_account_id = tostring(local.env.management_services.account_id)
  notifications_email            = local.config.notifications.environment_email
  tags                           = local.tags
}

module "backup_services" {
  source = "../../modules/backup-services"
  count  = try(local.baseline.enable_backup_services, true) ? 1 : 0

  tags = local.tags
}

module "federation" {
  source = "../../modules/federation"
  count  = try(local.config.federation.enabled, false) ? 1 : 0

  federation_name = local.config.federation.name
  tags            = local.tags
}

#
# Security Hub membership in the Central account (replaces the
# security_hub_invite_members pipeline Lambda).
#
resource "aws_securityhub_member" "this" {
  provider = aws.central

  account_id = var.account_id
  invite     = true

  depends_on = [module.security_baseline]
}

resource "aws_securityhub_invite_accepter" "this" {
  master_id = local.central_account_id

  depends_on = [aws_securityhub_member.this]
}

resource "terraform_data" "partition_check" {
  lifecycle {
    precondition {
      condition     = data.aws_partition.current.partition == try(local.config.partition, "aws-us-gov")
      error_message = "Credentials are for partition ${data.aws_partition.current.partition} but the config targets ${try(local.config.partition, "aws-us-gov")}."
    }
  }
}
