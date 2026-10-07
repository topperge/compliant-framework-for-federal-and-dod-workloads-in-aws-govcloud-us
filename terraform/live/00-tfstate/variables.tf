variable "config_file" {
  description = "Path to the framework configuration YAML. Defaults to terraform/config/framework.yaml."
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "Override the state bucket name (default: compliant-framework-tfstate-<account>-<region>)."
  type        = string
  default     = null
}
