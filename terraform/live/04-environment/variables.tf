variable "config_file" {
  description = "Path to the framework configuration YAML. Defaults to terraform/config/framework.yaml."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment to deploy (a key of `environments` in the config, e.g. prod). Use one state per environment."
  type        = string
}
