# Source: source/repositories/compliant-framework-management-services-core/templates/management-services-assets-bucket.yml

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  account_root_arn = "arn:${local.partition}:iam::${local.account_id}:root"

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

  kms_org_actions = [
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
# Assets S3 CMK
#
data "aws_iam_policy_document" "s3_bucket_cmk" {
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

  # Principal "*" is restricted to the AWS Organization (cfn_nag F76 suppressed in source)
  statement {
    sid       = "Allow Organization use of the key"
    effect    = "Allow"
    actions   = local.kms_org_actions
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

resource "aws_kms_key" "s3_bucket_cmk" {
  description         = "Assets - S3 CMK"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3_bucket_cmk.json
  tags                = var.tags
}

resource "aws_kms_alias" "s3_bucket_cmk" {
  name          = "alias/compliant-framework/assets/s3"
  target_key_id = aws_kms_key.s3_bucket_cmk.key_id
}

resource "aws_ssm_parameter" "cmk_arn" {
  name  = "/compliant/framework/management-services/assets-bucket-cmk/arn"
  type  = "String"
  value = aws_kms_key.s3_bucket_cmk.arn
  tags  = var.tags
}

#
# Assets bucket (DeletionPolicy/UpdateReplacePolicy: Retain in the source template)
#
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "environment-assets-${local.account_id}-${local.region}"
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  bucket                  = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      # Same value as the template: the alias ARN of the assets CMK
      kms_master_key_id = aws_kms_alias.s3_bucket_cmk.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

data "aws_iam_policy_document" "s3_bucket" {
  statement {
    sid       = "DenyInsecureConnections"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
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
    sid       = "AllowOrganizationAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
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

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.s3_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.s3_bucket]
}
