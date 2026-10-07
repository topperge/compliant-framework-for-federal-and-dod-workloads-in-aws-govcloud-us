variable "principal_org_id" {
  description = "AWS Organizations ID (o-xxxxxxxxxx) granted GetObject/PutObject on the bucket and use of the CMK (config.json central.organizationId)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
