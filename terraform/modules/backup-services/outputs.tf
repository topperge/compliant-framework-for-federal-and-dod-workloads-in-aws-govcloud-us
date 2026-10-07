output "aws_backup_automation_role" {
  description = "Role used for backup and restore processes (role name)."
  value       = aws_iam_role.aws_backup_automation_role.name
}

output "backup_policy1" {
  description = "Backup plan ID"
  value       = aws_backup_plan.backup_policy1.id
}

output "backup_policy1_vault" {
  description = "Backup vault name"
  value       = aws_backup_vault.backup_policy1_vault.name
}
