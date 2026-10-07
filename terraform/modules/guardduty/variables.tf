variable "finding_publishing_frequency" {
  description = "GuardDuty finding publishing frequency."
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "enable_s3_protection" {
  description = "Enable S3 data event protection (CFN DataSources.S3Logs.Enable)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
