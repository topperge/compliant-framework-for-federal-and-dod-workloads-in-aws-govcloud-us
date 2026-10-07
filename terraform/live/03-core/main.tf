# Core layer: replaces the core pipeline (source/repositories/compliant-framework-central-pipeline/lib/core-pipeline-stack.ts)
# which deployed logging-init.yml in the Logging account, central-init.yml in
# the Central account and invited the Logging account to Security Hub.
#
# The framework is deployed in the primary region (config.primary_region), as
# the CloudFormation version was in practice (deployToRegions = [us-gov-west-1]).

#
# Logging account (logging-init.yml)
#
module "logging_assets" {
  source    = "../../modules/logging-assets"
  providers = { aws = aws.logging }

  principal_org_id = data.aws_organizations_organization.this.id
  tags             = local.core_tags
}

module "logging_cloudtrail" {
  source    = "../../modules/cloudtrail"
  providers = { aws = aws.logging }

  logging_account_id = local.logging_account_id
  s3_bucket_name     = module.logging_assets.cloudtrail_s3_bucket_name
  kms_key_id         = module.logging_assets.logging_s3_bucket_cmk_arn
  tags               = local.core_tags
}

module "logging_config" {
  source    = "../../modules/config"
  providers = { aws = aws.logging }

  central_account_id      = local.central_account_id
  logging_account_id      = local.logging_account_id
  primary_region          = local.primary_region
  delivery_s3_bucket_name = module.logging_assets.config_s3_bucket_name
  tags                    = local.core_tags
}

module "logging_security_hub" {
  source    = "../../modules/security-hub"
  providers = { aws = aws.logging }

  central_account_id                   = local.central_account_id
  notifications_email                  = local.config.notifications.core_email
  cloudtrail_cloudwatch_log_group_name = module.logging_cloudtrail.cloudtrail_cloudwatch_log_group_name
  primary_region                       = local.primary_region
  # Invitations are accepted natively below, not through SecurityHubAccessRole.
  create_security_hub_access_role = false
  tags                            = local.core_tags
}

module "logging_guardduty" {
  source    = "../../modules/guardduty"
  providers = { aws = aws.logging }

  tags = local.core_tags
}

module "logging_iam_groups" {
  source    = "../../modules/iam-groups"
  providers = { aws = aws.logging }

  tags = local.core_tags
}

#
# Central account (central-init.yml)
#
resource "aws_ssm_parameter" "consolidated_logs_cmk_arn" {
  provider = aws.central

  name  = "/compliant/framework/consolidated-logs/cmk/arn"
  type  = "String"
  value = module.logging_assets.consolidated_logs_s3_bucket_cmk_arn
}

module "central_cloudtrail" {
  source    = "../../modules/cloudtrail"
  providers = { aws = aws.central }

  logging_account_id = local.logging_account_id
  s3_bucket_name     = module.logging_assets.cloudtrail_s3_bucket_name
  kms_key_id         = module.logging_assets.logging_s3_bucket_cmk_arn
  tags               = local.core_tags
}

module "central_config" {
  source    = "../../modules/config"
  providers = { aws = aws.central }

  central_account_id      = local.central_account_id
  logging_account_id      = local.logging_account_id
  primary_region          = local.primary_region
  delivery_s3_bucket_name = module.logging_assets.config_s3_bucket_name
  tags                    = local.core_tags
}

module "central_security_hub" {
  source    = "../../modules/security-hub"
  providers = { aws = aws.central }

  central_account_id                   = local.central_account_id
  notifications_email                  = local.config.notifications.core_email
  cloudtrail_cloudwatch_log_group_name = module.central_cloudtrail.cloudtrail_cloudwatch_log_group_name
  primary_region                       = local.primary_region
  tags                                 = local.core_tags
}

module "central_guardduty" {
  source    = "../../modules/guardduty"
  providers = { aws = aws.central }

  tags = local.core_tags
}

module "central_iam_groups" {
  source    = "../../modules/iam-groups"
  providers = { aws = aws.central }

  tags = local.core_tags
}

#
# Security Hub: Logging account becomes a member of the Central account
# (replaces the security_hub_invite_members pipeline Lambda).
#
resource "aws_securityhub_member" "logging" {
  provider = aws.central

  account_id = local.logging_account_id
  invite     = true

  depends_on = [module.central_security_hub, module.logging_security_hub]
}

resource "aws_securityhub_invite_accepter" "logging" {
  provider = aws.logging

  master_id = local.central_account_id

  depends_on = [aws_securityhub_member.logging]
}

#
# Federation roles in the core accounts (federation.yml deployed as plain
# stacks by the source environment's pipeline).
#
module "central_federation" {
  source    = "../../modules/federation"
  providers = { aws = aws.central }
  count     = try(local.config.federation.enabled, false) ? 1 : 0

  federation_name = local.config.federation.name
  tags            = local.core_tags
}

module "logging_federation" {
  source    = "../../modules/federation"
  providers = { aws = aws.logging }
  count     = try(local.config.federation.enabled, false) ? 1 : 0

  federation_name = local.config.federation.name
  tags            = local.core_tags
}
