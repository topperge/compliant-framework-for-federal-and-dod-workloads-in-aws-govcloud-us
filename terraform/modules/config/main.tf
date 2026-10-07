# Source: source/repositories/compliant-framework-central-core/templates/security/security-config.yml
#
# Deploy once per account per region. ConfigRole (global IAM) is created in the primary region only; non-primary
# region instances reference it by name, so apply the primary region first.

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  is_central_account                    = local.account_id == var.central_account_id
  is_primary_region                     = local.region == var.primary_region
  is_primary_region_and_central_account = local.is_central_account && local.is_primary_region

  config_role_arn = "arn:${local.partition}:iam::${local.account_id}:role/ConfigRole"
}

#
# AWS Config
#
resource "aws_iam_role" "config" {
  count = local.is_primary_region ? 1 : 0

  name = "ConfigRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count = local.is_primary_region ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/${var.config_role_managed_policy_name}"
}

resource "aws_config_configuration_recorder" "config" {
  name     = var.configuration_recorder_name
  role_arn = local.config_role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = local.is_primary_region
  }

  depends_on = [aws_iam_role_policy_attachment.config]
}

resource "aws_config_delivery_channel" "config" {
  name           = var.delivery_channel_name
  s3_bucket_name = "config-${var.logging_account_id}-${var.primary_region}"

  snapshot_delivery_properties {
    delivery_frequency = var.config_delivery_frequency
  }

  depends_on = [aws_config_configuration_recorder.config]
}

# CloudFormation starts the recorder implicitly; Terraform needs an explicit status resource
resource "aws_config_configuration_recorder_status" "config" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.config]
}

#
# Organization aggregator (central account, primary region only)
#
resource "aws_iam_role" "config_aggregator" {
  count = local.is_primary_region_and_central_account ? 1 : 0

  name = var.config_aggregator_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config_aggregator" {
  count = local.is_primary_region_and_central_account ? 1 : 0

  role       = aws_iam_role.config_aggregator[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_config_configuration_aggregator" "config" {
  count = local.is_primary_region_and_central_account ? 1 : 0

  name = "config-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator[0].arn
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.config_aggregator]
}
