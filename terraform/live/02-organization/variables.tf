variable "config_file" {
  description = "Path to the framework configuration YAML. Defaults to terraform/config/framework.yaml."
  type        = string
  default     = null
}

variable "aws_service_access_principals" {
  description = "Service principals with trusted access to the organization. Include any principals already enabled before importing an existing organization, otherwise Terraform disables them."
  type        = list(string)
  default = [
    "ram.amazonaws.com",
    "servicecatalog.amazonaws.com",
  ]
}

variable "enabled_policy_types" {
  description = "Organization policy types to enable (e.g. SERVICE_CONTROL_POLICY)."
  type        = list(string)
  default     = []
}
