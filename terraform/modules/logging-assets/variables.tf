variable "principal_org_id" {
  description = "AWS Organizations ID (o-xxxxxxxxxx) allowed to use the logging CMKs and replicate into the consolidated logs bucket (CFN pPrincipalOrgId; config.json central.organizationId)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
