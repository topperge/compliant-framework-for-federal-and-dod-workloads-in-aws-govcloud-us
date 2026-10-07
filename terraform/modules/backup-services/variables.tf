##################### GLOBAL PARAMETERS ########################################
variable "backup_admin_role_name" {
  description = "Name of the IAM role assumed by AWS Backup (CFN pBackupAdminRoleName)."
  type        = string
  default     = "BackupAdmin"
}

variable "backup_tag_key" {
  description = "Resource tag key used to select resources for backup (CFN pBackupTagKey)."
  type        = string
  default     = "BackupPolicy"
}

variable "backup_cancel_minutes" {
  description = "Backup start window in minutes (CFN pBackupCancelMinutes)."
  type        = number
  default     = 240
}

variable "backup_completion_minutes" {
  description = "Backup completion window in minutes (CFN pBackupCompletionMinutes)."
  type        = number
  default     = 720
}

#################### Policy 1 Parameters #######################################
variable "backup_policy1_name" {
  description = "Backup plan name (CFN pBackupPolicy1Name)."
  type        = string
  default     = "standard"
}

variable "backup_policy1_vault_name" {
  description = "Backup vault name; should normally match the backup policy name (CFN pBackupPolicy1VaultName)."
  type        = string
  default     = "standard"
}

variable "backup_policy1_days" {
  description = "Days to retain daily backups; null = never delete (CFN pBackupPolicy1Days, \"\" in CFN)."
  type        = number
  default     = 14
}

variable "backup_policy1_weeks" {
  description = "Days to retain weekly backups; null = never delete (CFN pBackupPolicy1Weeks)."
  type        = number
  default     = 42
}

variable "backup_policy1_months" {
  description = "Days to retain monthly backups; null = never delete (CFN pBackupPolicy1Months)."
  type        = number
  default     = 365
}

variable "backup_policy1_to_cold_store_days" {
  description = "Days after which monthly backups move to cold storage; null = no cold storage (CFN pBackupPolicy1ToColdStoreDays)."
  type        = number
  default     = 60
}

variable "backup_policy1_tag_value" {
  description = "Tag value selecting resources for this plan; also used as rule/selection name prefix (CFN pBackupPolicy1TagValue)."
  type        = string
  default     = "standard"
}

variable "backup_policy1_daily_schedule" {
  description = "Daily schedule, cron body in parentheses; default runs daily at 5:00 AM EST (CFN pBackupPolicy1DailySchedule)."
  type        = string
  default     = "(0 9 * * ? *)"
}

variable "backup_policy1_weekly_schedule" {
  description = "Weekly schedule; default runs Sunday at 5:00 AM EST (CFN pBackupPolicy1WeeklySchedule)."
  type        = string
  default     = "(0 9 ? * SUN *)"
}

variable "backup_policy1_monthly_schedule" {
  description = "Monthly schedule; default runs the first day of each month at 5:00 AM EST (CFN pBackupPolicy1MonthlySchedule)."
  type        = string
  default     = "(0 9 1 * ? *)"
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
