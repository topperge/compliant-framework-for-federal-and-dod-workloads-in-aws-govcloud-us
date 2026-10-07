variable "central_account_id" {
  description = "Central (Security Hub administrator) account ID. Trusted by SecurityHubAccessRole in member accounts (CFN pCentralAccountId)."
  type        = string
}

variable "notifications_email" {
  description = "Email subscribed to the SecurityHub-CIS-Alarms SNS topic (CFN pNotificationsEmail; config.json core.notificationsEmail)."
  type        = string
}

variable "cloudtrail_cloudwatch_log_group_name" {
  description = "CloudTrail CloudWatch log group that the CIS metric filters watch (cloudtrail module output). Required in the primary region; ignored elsewhere (CFN pCloudTrailCloudWatchLogGroupName)."
  type        = string
  default     = ""
}

variable "primary_region" {
  description = "Primary region (config.json core.primaryRegion). Metric filters, the password policy and the access role are only created there (CFN pPrimaryRegion)."
  type        = string
  default     = "us-gov-west-1"
}

variable "enable_default_standards" {
  description = "Whether enabling Security Hub also subscribes the default standards (matches AWS::SecurityHub::Hub default behaviour)."
  type        = bool
  default     = true
}

variable "create_security_hub_access_role" {
  description = "Create SecurityHubAccessRole (cross-account role the central account assumed to accept invitations) when in the primary region of a non-central account. Can be disabled once invitations are accepted natively by Terraform."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
