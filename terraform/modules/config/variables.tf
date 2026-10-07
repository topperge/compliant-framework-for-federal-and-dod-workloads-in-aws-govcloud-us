variable "central_account_id" {
  description = "Central (GovCloud management) account ID; the organization config aggregator is created only there, in the primary region (CFN pCentralAccountId)."
  type        = string
}

variable "logging_account_id" {
  description = "Logging account ID owning the config-<account>-<primary region> delivery bucket (CFN pLoggingAccountId)."
  type        = string
}

variable "primary_region" {
  description = "Primary region (config.json core.primaryRegion). Global resource types, ConfigRole and the aggregator are only handled there (CFN pPrimaryRegion)."
  type        = string
  default     = "us-gov-west-1"
}

variable "config_delivery_frequency" {
  description = "AWS Config snapshot delivery frequency (CFN pConfigDeliveryFrequency)."
  type        = string
  default     = "Three_Hours"
}

variable "configuration_recorder_name" {
  description = "Name of the configuration recorder. CFN generated this name; set it to the existing name when importing."
  type        = string
  default     = "default"
}

variable "delivery_channel_name" {
  description = "Name of the delivery channel. CFN generated this name; set it to the existing name when importing."
  type        = string
  default     = "default"
}

variable "config_role_managed_policy_name" {
  description = "AWS managed policy (under iam::aws:policy/service-role/) attached to ConfigRole. Source used the legacy AWSConfigRole; AWS_ConfigRole is its replacement."
  type        = string
  default     = "AWSConfigRole"
}

variable "config_aggregator_role_name" {
  description = "Name of the IAM role used by the organization config aggregator. CFN generated this name; set it to the existing name when importing."
  type        = string
  default     = "CompliantFrameworkConfigAggregatorRole"
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
