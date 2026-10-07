variable "federation_name" {
  description = "Name of the pre-existing IAM SAML provider in this account; also the role-name prefix (CFN pFederationName; config federation.name, e.g. \"KeyCloak\")."
  type        = string
}

variable "saml_endpoint" {
  description = "Expected SAML:aud value in the role trust policies (CFN pSamlEndpoint)."
  type        = string
  default     = "https://signin.aws.amazon.com/saml"
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
