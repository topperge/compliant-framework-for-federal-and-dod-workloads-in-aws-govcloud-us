# Source: source/repositories/compliant-framework-security-baseline/templates/security-baseline.yml
# Per-account security baseline (formerly deployed as a service-managed StackSet to every member account).

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  # CFN Conditions
  is_not_govcloud        = !contains(["us-gov-west-1", "us-gov-east-1"], local.region) # cIsNotGovCloud
  is_not_govcloud_east_1 = local.region != "us-gov-east-1"                             # cIsNotGovCloudEast1
  conditions = {
    cIsNotGovCloud      = local.is_not_govcloud
    cIsNotGovCloudEast1 = local.is_not_govcloud_east_1
  }
}

#
# AWS CloudTrail
#
resource "aws_cloudwatch_log_group" "cloudtrail_cloudwatch_log_group" {
  name              = var.cloudtrail_log_group_name
  retention_in_days = 365
  tags              = var.tags
}

resource "aws_iam_role" "cloudtrail_cloudwatch_log_group_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_log_group_role" {
  name = "allow-access-to-cw-logs"
  role = aws_iam_role.cloudtrail_cloudwatch_log_group_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Resource = [
        "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail_cloudwatch_log_group.name}:log-stream:${local.account_id}*",
      ]
    }]
  })
}

resource "aws_cloudtrail" "cloudtrail" {
  name                          = var.cloudtrail_name
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_cloudwatch_log_group.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_log_group_role.arn
  enable_log_file_validation    = true
  include_global_service_events = true
  enable_logging                = true
  is_multi_region_trail         = true
  s3_bucket_name                = "cloudtrail-${var.management_services_account_id}-${local.region}"
  kms_key_id                    = "arn:${local.partition}:kms:${local.region}:${var.management_services_account_id}:alias/compliant-framework/logging/s3"

  event_selector {
    include_management_events = true
    read_write_type           = "All"

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:${local.partition}:s3:::"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:${local.partition}:lambda"]
    }
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy.cloudtrail_cloudwatch_log_group_role]
}

#
# AWS Config
#
resource "aws_iam_role" "config_role" {
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

resource "aws_iam_role_policy_attachment" "config_role" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_configuration_recorder" "config_configuration_recorder" {
  name     = var.config_recorder_name
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "config_delivery_channel" {
  name           = var.config_delivery_channel_name
  s3_bucket_name = "config-${var.management_services_account_id}-${local.region}"

  snapshot_delivery_properties {
    delivery_frequency = var.config_delivery_frequency
  }

  depends_on = [aws_config_configuration_recorder.config_configuration_recorder]
}

# CloudFormation starts the recorder implicitly; Terraform needs an explicit status resource.
resource "aws_config_configuration_recorder_status" "config_configuration_recorder" {
  name       = aws_config_configuration_recorder.config_configuration_recorder.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.config_delivery_channel]
}

#
# Security Hub
#
resource "aws_securityhub_account" "security_hub" {
  depends_on = [
    aws_cloudtrail.cloudtrail,
    aws_config_delivery_channel.config_delivery_channel,
    aws_config_configuration_recorder_status.config_configuration_recorder,
    aws_iam_role.config_role,
    aws_cloudwatch_log_group.cloudtrail_cloudwatch_log_group,
    aws_sns_topic.security_hub_alarm_notification_topic,
  ]
}

#
# IAM account password policy (replaces Custom::ConfigureIamPolicy and its Lambda/role)
#
resource "aws_iam_account_password_policy" "configure_iam_policy" {
  minimum_password_length        = 14
  require_symbols                = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = true
}

#
# Amazon GuardDuty
#
resource "aws_guardduty_detector" "guard_duty_detector" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  tags                         = var.tags
}

# DataSources.S3Logs.Enable = true
resource "aws_guardduty_detector_feature" "guard_duty_detector_s3_logs" {
  detector_id = aws_guardduty_detector.guard_duty_detector.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}
