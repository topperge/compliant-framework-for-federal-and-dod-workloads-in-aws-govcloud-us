# Source: source/repositories/compliant-framework-central-core/templates/logging/logging-assets.yml

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id
  root_arn   = "arn:${local.partition}:iam::${local.account_id}:root"

  cloudtrail_bucket_name        = "cloudtrail-${local.account_id}-${local.region}"
  config_bucket_name            = "config-${local.account_id}-${local.region}"
  flow_logs_bucket_name         = "flow-logs-${local.account_id}-${local.region}"
  consolidated_logs_bucket_name = "consolidated-logs-${local.account_id}-${local.region}"

  # Source log buckets that replicate into the consolidated logs bucket
  source_buckets = {
    cloudtrail = aws_s3_bucket.cloudtrail
    config     = aws_s3_bucket.config
    flow_logs  = aws_s3_bucket.flow_logs
  }
}

#
# Logging S3 CMK (encrypts cloudtrail / config / flow-logs buckets)
#
data "aws_iam_policy_document" "logging_s3_bucket_cmk" {
  policy_id = "key-policy-1"

  statement {
    sid = "Allow administration of the key"
    principals {
      type        = "AWS"
      identifiers = [local.root_arn]
    }
    actions = [
      "kms:CancelKeyDeletion",
      "kms:CreateAlias",
      "kms:CreateGrant",
      "kms:CreateKey",
      "kms:DeleteAlias",
      "kms:DeleteImportedKeyMaterial",
      "kms:DescribeKey",
      "kms:DisableKey",
      "kms:DisableKeyRotation",
      "kms:EnableKey",
      "kms:EnableKeyRotation",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GenerateRandom",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:GetParametersForImport",
      "kms:ImportKeyMaterial",
      "kms:ListAliases",
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListKeys",
      "kms:ListResourceTags",
      "kms:ListRetirableGrants",
      "kms:PutKeyPolicy",
      "kms:RetireGrant",
      "kms:RevokeGrant",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:UpdateAlias",
      "kms:UpdateKeyDescription",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Allow Account root use of the key"
    principals {
      type        = "AWS"
      identifiers = [local.root_arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GenerateRandom",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListKeys",
      "kms:ListResourceTags",
      "kms:ListRetirableGrants",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Allow S3 service use of the key"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GenerateRandom",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListGrants",
      "kms:ListKeyPolicies",
      "kms:ListKeys",
      "kms:ListResourceTags",
      "kms:ListRetirableGrants",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Allow VPC Flow Logs use of the key"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Allow CloudTrail use of the key"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]
  }

  # Principal "*" restricted to the organization (cfn_nag F76 suppressed in source)
  statement {
    sid = "Allow Organization use of the key"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.principal_org_id]
    }
  }
}

resource "aws_kms_key" "logging_s3_bucket_cmk" {
  description         = "Logging - S3 CMK"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.logging_s3_bucket_cmk.json
  tags                = var.tags
}

resource "aws_kms_alias" "logging_s3_bucket_cmk" {
  name          = "alias/compliant-framework/logging/s3"
  target_key_id = aws_kms_key.logging_s3_bucket_cmk.key_id
}

resource "aws_ssm_parameter" "logging_s3_bucket_cmk" {
  name  = "/compliant/framework/logging/logging-bucket-cmk/arn"
  type  = "String"
  value = aws_kms_key.logging_s3_bucket_cmk.arn
  tags  = var.tags
}

#
# Consolidated logs S3 CMK
#
data "aws_iam_policy_document" "consolidated_logs_s3_bucket_cmk" {
  policy_id = "key-policy-1"

  statement {
    sid = "Allow administration of the key"
    principals {
      type        = "AWS"
      identifiers = [local.root_arn]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid = "Allow Account root use of the key"
    principals {
      type        = "AWS"
      identifiers = [local.root_arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Enable Organization access for S3 Replication"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["kms:Encrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.principal_org_id]
    }
  }
}

resource "aws_kms_key" "consolidated_logs_s3_bucket_cmk" {
  description         = "Logging - S3 CMK"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.consolidated_logs_s3_bucket_cmk.json
  tags                = var.tags
}

resource "aws_kms_alias" "consolidated_logs_s3_bucket_cmk" {
  name          = "alias/compliant-framework/consolidated-logs/s3"
  target_key_id = aws_kms_key.consolidated_logs_s3_bucket_cmk.key_id
}
