variable "logging_account_id" {
  description = "Logging account ID that owns the cloudtrail-<account>-<region> bucket and the alias/compliant-framework/logging/s3 CMK (CFN pLoggingAccountId)."
  type        = string
}

variable "s3_bucket_name" {
  description = "Override for the trail bucket (default cloudtrail-<logging_account_id>-<region>). Passing logging-assets' cloudtrail_s3_bucket_name output gives an implicit dependency instead of module-level depends_on."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "Override for the trail CMK (default arn:<partition>:kms:<region>:<logging_account_id>:alias/compliant-framework/logging/s3)."
  type        = string
  default     = null
}

variable "trail_name" {
  description = "CloudTrail trail name. CFN generated this name; set it to the existing trail name when importing."
  type        = string
  default     = "compliant-framework-cloudtrail"
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group receiving CloudTrail events. CFN generated this name; set it to the existing name when importing."
  type        = string
  default     = "/compliant-framework/cloudtrail"
}

variable "cloudwatch_log_group_role_name" {
  description = "Name of the IAM role CloudTrail assumes to write to CloudWatch Logs. CFN generated this name; set it to the existing name when importing."
  type        = string
  default     = "CompliantFrameworkCloudTrailCloudWatchLogsRole"
}

variable "cloudwatch_log_retention_in_days" {
  description = "Retention of the CloudTrail CloudWatch log group."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
