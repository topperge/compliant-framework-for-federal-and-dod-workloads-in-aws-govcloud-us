# Source: source/repositories/compliant-framework-central-core/templates/security/security-hub.yml
#
# Deploy once per account per region (central, logging and every member account).

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id
  root_arn   = "arn:${local.partition}:iam::${local.account_id}:root"

  is_primary_region                 = local.region == var.primary_region
  create_security_hub_access_role = (
    var.create_security_hub_access_role && local.is_primary_region && local.account_id != var.central_account_id
  )
}

#
# Security Hub
#
resource "aws_securityhub_account" "security_hub" {
  enable_default_standards = var.enable_default_standards

  depends_on = [aws_sns_topic.security_hub_alarm_notification]
}

# Cross account access role to accept invites (cfn_nag W11: securityhub invitation APIs do not support resource scoping)
resource "aws_iam_role" "security_hub_access" {
  count = local.create_security_hub_access_role ? 1 : 0

  name = "SecurityHubAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:${local.partition}:iam::${var.central_account_id}:root" }
      Action    = ["sts:AssumeRole"]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "security_hub_access" {
  count = local.create_security_hub_access_role ? 1 : 0

  name = "security-hub-accept-invite"
  role = aws_iam_role.security_hub_access[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "securityhub:AcceptInvitation",
        "securityhub:ListInvitations",
      ]
      Resource = "*"
    }]
  })
}

#
# IAM account password policy (was the rConfigureIamPolicy custom resource + Lambda)
#
resource "aws_iam_account_password_policy" "configure_iam_policy" {
  count = local.is_primary_region ? 1 : 0

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
# CIS alarm notification topic + CMK
#
data "aws_iam_policy_document" "security_hub_alarm_notification_topic_cmk" {
  policy_id = "key-policy-1"

  statement {
    sid = "Allow administration of the key"
    principals {
      type        = "AWS"
      identifiers = [local.root_arn]
    }
    actions = [
      "kms:ListGrants",
      "kms:GenerateRandom",
      "kms:TagResource",
      "kms:CreateAlias",
      "kms:ListKeyPolicies",
      "kms:ListResourceTags",
      "kms:CreateGrant",
      "kms:RevokeGrant",
      "kms:GetKeyPolicy",
      "kms:ListKeys",
      "kms:ListRetirableGrants",
      "kms:PutKeyPolicy",
      "kms:ListAliases",
      "kms:CancelKeyDeletion",
      "kms:DisableKey",
      "kms:DeleteAlias",
      "kms:DescribeKey",
      "kms:ImportKeyMaterial",
      "kms:UpdateKeyDescription",
      "kms:GetKeyRotationStatus",
      "kms:DeleteImportedKeyMaterial",
      "kms:DisableKeyRotation",
      "kms:UpdateAlias",
      "kms:UntagResource",
      "kms:RetireGrant",
      "kms:EnableKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:EnableKeyRotation",
      "kms:ScheduleKeyDeletion",
      "kms:GetParametersForImport",
      "kms:CreateKey",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Allow Cloudtrail use of the key"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "security_hub_alarm_notification_topic_cmk" {
  description         = "Logging - S3 CMK"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.security_hub_alarm_notification_topic_cmk.json
  tags                = var.tags
}

resource "aws_kms_alias" "security_hub_alarm_notification_topic_cmk" {
  name          = "alias/compliant-framework/security-hub/sns"
  target_key_id = aws_kms_key.security_hub_alarm_notification_topic_cmk.key_id
}

resource "aws_sns_topic" "security_hub_alarm_notification" {
  name              = "SecurityHub-CIS-Alarms"
  kms_master_key_id = aws_kms_alias.security_hub_alarm_notification_topic_cmk.name
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "security_hub_alarm_notification" {
  topic_arn = aws_sns_topic.security_hub_alarm_notification.arn
  protocol  = "email"
  endpoint  = var.notifications_email
}
