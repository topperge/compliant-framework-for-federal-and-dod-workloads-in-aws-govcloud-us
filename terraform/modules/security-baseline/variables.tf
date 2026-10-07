variable "central_account_id" {
  description = "Central (GovCloud management) account id; trusted by SecurityHubAccessRole and the CompliantFramework*AccessRole roles (CFN pCentralAccountId)."
  type        = string
}

variable "management_services_account_id" {
  description = "Management-services (logging) account id that owns the cloudtrail-/config- buckets, the logging S3 CMK and CompliantFrameworkCfnRunnerRole (CFN pManagementServicesAccountId)."
  type        = string
}

variable "notifications_email" {
  description = "Email subscribed to the SecurityHub-CIS-Alarms SNS topic (CFN pNotificationsEmail; config stackSets.security-baseline.parameters, SSM /compliant/framework/central/stack-set/parameters/security-baseline)."
  type        = string
}

variable "config_delivery_frequency" {
  description = "AWS Config snapshot delivery frequency (CFN pConfigDeliveryFrequency)."
  type        = string
  default     = "Three_Hours"
}

# ---------------------------------------------------------------------------------------------------------------------
# Names CloudFormation generated automatically. Terraform needs (or should have) explicit values; when importing an
# existing StackSet instance set these to the physical names CloudFormation generated in that account.
# ---------------------------------------------------------------------------------------------------------------------
variable "cloudtrail_name" {
  description = "Name of the multi-region trail (CFN rCloudTrail had a generated name)."
  type        = string
  default     = "compliant-framework-security-baseline"
}

variable "cloudtrail_log_group_name" {
  description = "CloudWatch log group receiving CloudTrail events (CFN rCloudTrailCloudWatchLogGroup had a generated name). null = let Terraform generate one."
  type        = string
  default     = null
}

variable "config_recorder_name" {
  description = "AWS Config configuration recorder name (CFN generated). Only one recorder per account/region may exist."
  type        = string
  default     = "default"
}

variable "config_delivery_channel_name" {
  description = "AWS Config delivery channel name (CFN generated). Only one channel per account/region may exist."
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
