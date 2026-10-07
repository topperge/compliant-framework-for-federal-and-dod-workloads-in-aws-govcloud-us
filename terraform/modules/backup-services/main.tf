# Source: source/repositories/compliant-framework-security-baseline/templates/backup-services.yml
# AWS Backup policy deployment (formerly a service-managed StackSet to every member account).

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  account_id = data.aws_caller_identity.current.account_id

  backup_policy1_rules = {
    daily = {
      schedule     = var.backup_policy1_daily_schedule
      delete_after = var.backup_policy1_days # cPolicy1LifecycleDays
      cold_storage = null
    }
    weekly = {
      schedule     = var.backup_policy1_weekly_schedule
      delete_after = var.backup_policy1_weeks # cPolicy1LifecycleWeeks
      cold_storage = null
    }
    monthly = {
      schedule     = var.backup_policy1_monthly_schedule
      delete_after = var.backup_policy1_months             # cPolicy1LifecycleMonths
      cold_storage = var.backup_policy1_to_cold_store_days # cPolicy1ColdStorage
    }
  }
}

########## CREATE SERVICE ROLE FOR BACKUP AND RESTORE ##########################

# Role that allows the AWS Backup service to assume it for managed backup activities
resource "aws_iam_role" "aws_backup_automation_role" {
  name = var.backup_admin_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Principal = {
        Service = [
          "backup.amazonaws.com",
          "lambda.amazonaws.com",
        ]
      }
      Action = ["sts:AssumeRole"]
    }
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_backup_automation_role" {
  for_each = toset([
    "service-role/AWSBackupServiceRolePolicyForBackup",
    "service-role/AWSBackupServiceRolePolicyForRestores",
  ])

  role       = aws_iam_role.aws_backup_automation_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/${each.value}"
}

########## CREATE KMS KEY ######################################################

# KMS key protecting backups
resource "aws_kms_key" "kms_key" {
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "backup-key-policy"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:${local.partition}:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow administration of the key"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.aws_backup_automation_role.arn }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
        ]
        Resource = "*"
      },
      {
        Sid       = "Allow use of the key"
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.aws_backup_automation_role.arn }
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
        ]
        Resource = "*"
      },
    ]
  })
  tags = var.tags
}

########## CREATE BACKUP POLICY 1 ##############################################

# Separate vault in the primary region
resource "aws_backup_vault" "backup_policy1_vault" {
  name        = var.backup_policy1_vault_name
  kms_key_arn = aws_kms_key.kms_key.arn
  tags        = var.tags
}

resource "aws_backup_plan" "backup_policy1" {
  name = var.backup_policy1_name

  dynamic "rule" {
    for_each = local.backup_policy1_rules
    content {
      rule_name         = "${var.backup_policy1_tag_value}_${rule.key}"
      target_vault_name = aws_backup_vault.backup_policy1_vault.name
      schedule          = "cron${rule.value.schedule}"
      start_window      = var.backup_cancel_minutes
      completion_window = var.backup_completion_minutes

      dynamic "lifecycle" {
        for_each = rule.value.delete_after != null || rule.value.cold_storage != null ? [rule.value] : []
        content {
          delete_after       = lifecycle.value.delete_after
          cold_storage_after = lifecycle.value.cold_storage
        }
      }
    }
  }

  tags = var.tags
}

# Associates target resources with the plan based on the tag value
resource "aws_backup_selection" "backup_policy1_resources" {
  name         = var.backup_policy1_tag_value
  plan_id      = aws_backup_plan.backup_policy1.id
  iam_role_arn = aws_iam_role.aws_backup_automation_role.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = var.backup_policy1_tag_value
  }

  depends_on = [aws_iam_role_policy_attachment.aws_backup_automation_role]
}
