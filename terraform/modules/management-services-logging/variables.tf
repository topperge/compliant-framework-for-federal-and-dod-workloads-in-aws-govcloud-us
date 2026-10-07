variable "principal_org_id" {
  description = "AWS Organizations ID (o-xxxxxxxxxx) allowed to use the logging CMK (config.json central.organizationId)."
  type        = string
}

variable "logging_account_id" {
  description = "Account ID of the logging account that owns the consolidated-logs-<account>-<primary region> bucket (config.json logging.accountId)."
  type        = string
}

variable "consolidated_logs_s3_bucket_cmk_arn" {
  description = "ARN of the consolidated logs bucket CMK in the logging account (previously read from SSM /compliant/framework/consolidated-logs/cmk/arn in the central account)."
  type        = string
}

variable "primary_region" {
  description = "Primary region of the framework (config.json core.primaryRegion); the consolidated logs bucket lives there."
  type        = string
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
