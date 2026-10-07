variable "config_file" {
  description = "Path to the framework configuration YAML. Defaults to terraform/config/framework.yaml."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment the account belongs to (a key of `environments` in the config)."
  type        = string
}

variable "account_id" {
  description = "Member account to baseline (transit, management-services or tenant account of the environment). Use one state per account."
  type        = string
}
