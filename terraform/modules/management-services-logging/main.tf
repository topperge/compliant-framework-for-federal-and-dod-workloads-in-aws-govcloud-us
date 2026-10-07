# Source: source/repositories/compliant-framework-management-services-core/templates/management-services-logging-assets.yml
# (wrapped by management-services-logging.yml)

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  account_root_arn = "arn:${local.partition}:iam::${local.account_id}:root"

  consolidated_logs_bucket_arn = "arn:${local.partition}:s3:::consolidated-logs-${var.logging_account_id}-${var.primary_region}"

  cloudtrail_bucket_name = "cloudtrail-${local.account_id}-${local.region}"
  config_bucket_name     = "config-${local.account_id}-${local.region}"
  flow_logs_bucket_name  = "flow-logs-${local.account_id}-${local.region}"

  # Buckets replicated to the consolidated logs bucket in the logging account
  replicated_buckets = {
    cloudtrail = aws_s3_bucket.cloudtrail
    config     = aws_s3_bucket.config
    flow_logs  = aws_s3_bucket.flow_logs
  }

  kms_admin_actions = [
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

  kms_use_actions = [
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

  kms_service_actions = [
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
}

#
# Logging S3 CMK
#
data "aws_iam_policy_document" "logging_s3_bucket_cmk" {
  policy_id = "key-policy-1"

  statement {
    sid       = "Allow administration of the key"
    effect    = "Allow"
    actions   = local.kms_admin_actions
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [local.account_root_arn]
    }
  }

  statement {
    sid       = "Allow Account root use of the key"
    effect    = "Allow"
    actions   = local.kms_use_actions
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [local.account_root_arn]
    }
  }

  statement {
    sid       = "Allow S3 service use of the key"
    effect    = "Allow"
    actions   = local.kms_use_actions
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }

  statement {
    sid       = "Allow VPC Flow Logs use of the key"
    effect    = "Allow"
    actions   = local.kms_service_actions
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "Allow CloudTrail use of the key"
    effect    = "Allow"
    actions   = local.kms_service_actions
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  # Principal "*" is restricted to the AWS Organization (cfn_nag F76 suppressed in source)
  statement {
    sid       = "Allow Organization use of the key"
    effect    = "Allow"
    actions   = local.kms_service_actions
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
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
  name  = "/compliant/framework/management-services/logging-bucket-cmk/arn"
  type  = "String"
  value = aws_kms_key.logging_s3_bucket_cmk.arn
  tags  = var.tags
}

#
# Log buckets (DeletionPolicy/UpdateReplacePolicy: Retain in the source template)
#
resource "aws_s3_bucket" "cloudtrail" {
  bucket = local.cloudtrail_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "config" {
  bucket = local.config_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "flow_logs" {
  bucket = local.flow_logs_bucket_name
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.replicated_buckets

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = local.replicated_buckets

  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.replicated_buckets

  bucket = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      # Same value as the template: the alias ARN of the logging CMK
      kms_master_key_id = aws_kms_alias.logging_s3_bucket_cmk.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Cross-account replication to consolidated-logs-<logging account>-<primary region>
resource "aws_s3_bucket_replication_configuration" "this" {
  for_each = local.replicated_buckets

  bucket = each.value.id
  role   = aws_iam_role.consolidated_logs_replication.arn

  rule {
    id     = "ConsolidatedLogs"
    status = "Enabled"
    # No filter block => legacy (V1) replication schema with an empty prefix, as in the template.

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = local.consolidated_logs_bucket_arn
      account       = var.logging_account_id
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = var.consolidated_logs_s3_bucket_cmk_arn
      }

      access_control_translation {
        owner = "Destination"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

#
# Bucket policies
#
data "aws_iam_policy_document" "cloudtrail" {
  statement {
    sid       = "DenyInsecureConnections"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

data "aws_iam_policy_document" "config" {
  statement {
    sid       = "DenyInsecureConnections"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.config.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config.arn]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSConfigBucketExistenceCheck"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.config.arn]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id
  policy = data.aws_iam_policy_document.config.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

data "aws_iam_policy_document" "flow_logs" {
  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.flow_logs.arn}/AWSLogs/*/*"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.flow_logs.arn]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

#
# Consolidated logging support (for cross account copy)
#
data "aws_iam_policy_document" "consolidated_logs_replication_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "consolidated_logs_replication" {
  name               = "ConsolidatedLogsReplicationRole"
  assume_role_policy = data.aws_iam_policy_document.consolidated_logs_replication_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "consolidated_logs_replication" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
    ]
    resources = flatten([for b in values(local.replicated_buckets) : [b.arn, "${b.arn}/*"]])
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${local.consolidated_logs_bucket_arn}/*"]
    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms", "AES256"]
    }
    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [var.consolidated_logs_s3_bucket_cmk_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.logging_s3_bucket_cmk.arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${var.primary_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [for b in values(local.replicated_buckets) : "${b.arn}/*"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Encrypt"]
    resources = [var.consolidated_logs_s3_bucket_cmk_arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${var.primary_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${local.consolidated_logs_bucket_arn}/*"]
    }
  }
}

resource "aws_iam_role_policy" "consolidated_logs_replication" {
  name   = "AllowReplicationAccess"
  role   = aws_iam_role.consolidated_logs_replication.id
  policy = data.aws_iam_policy_document.consolidated_logs_replication.json
}
