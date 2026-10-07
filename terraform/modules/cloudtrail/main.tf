# Source: source/repositories/compliant-framework-central-core/templates/security/security-cloudtrail.yml
#
# Deploy only in the primary region (multi-region trail).

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id
}

#
# AWS CloudTrail
#
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_retention_in_days
  tags              = var.tags
}

resource "aws_iam_role" "cloudtrail_cloudwatch_log_group" {
  name = var.cloudwatch_log_group_role_name
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

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_log_group" {
  name = "allow-access-to-cw-logs"
  role = aws_iam_role.cloudtrail_cloudwatch_log_group.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Resource = [
        "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.name}:log-stream:${local.account_id}*",
      ]
    }]
  })
}

resource "aws_cloudtrail" "cloudtrail" {
  name                          = var.trail_name
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_log_group.arn
  enable_log_file_validation    = true
  include_global_service_events = true
  enable_logging                = true
  is_multi_region_trail         = true
  s3_bucket_name                = "cloudtrail-${var.logging_account_id}-${local.region}"
  kms_key_id                    = "arn:${local.partition}:kms:${local.region}:${var.logging_account_id}:alias/compliant-framework/logging/s3"

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

  # The role policy must exist before CloudTrail validates log delivery
  depends_on = [aws_iam_role_policy.cloudtrail_cloudwatch_log_group]
}
