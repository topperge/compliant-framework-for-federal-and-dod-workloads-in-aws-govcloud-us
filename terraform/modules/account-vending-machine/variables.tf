variable "tags" {
  description = "Tags applied to all taggable resources created by this module."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------------------------------------------------
# GovCloud credentials / target
# ---------------------------------------------------------------------------------------------------------------------
variable "govcloud_access_key_id_parameter_name" {
  description = "Name of the SSM parameter (in this commercial management account) holding the access key id of the IAM user in the GovCloud central (management) account. Created manually, not by this module."
  type        = string
  default     = "/compliant/framework/central-avm/aws-us-gov/access-key-id"
}

variable "govcloud_secret_access_key_parameter_name" {
  description = "Name of the SSM SecureString parameter (in this commercial management account) holding the secret access key of the IAM user in the GovCloud central (management) account. Created manually, not by this module."
  type        = string
  default     = "/compliant/framework/central-avm/aws-us-gov/secret-access-key"
}

variable "ssm_kms_key_arn" {
  description = "Optional customer managed KMS key ARN used to encrypt the GovCloud credential SecureString parameters. When set, kms:Decrypt on it is granted to the Lambdas that read them. Leave null for the AWS managed aws/ssm key."
  type        = string
  default     = null
}

variable "govcloud_region" {
  description = "GovCloud region used for the Organizations/STS API calls made with the GovCloud credentials (hardcoded in the original Lambdas)."
  type        = string
  default     = "us-gov-west-1"
}

# ---------------------------------------------------------------------------------------------------------------------
# Lambda
# ---------------------------------------------------------------------------------------------------------------------
variable "lambda_runtime" {
  description = "Python runtime for the AVM Lambdas. The CDK app used python3.8, which AWS Lambda no longer accepts for new functions."
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Timeout (seconds) of the AVM Lambdas."
  type        = number
  default     = 900
}

# ---------------------------------------------------------------------------------------------------------------------
# Service Catalog product template storage
# ---------------------------------------------------------------------------------------------------------------------
variable "create_template_bucket" {
  description = "Create the S3 bucket that holds the Service Catalog product template. When false, template_bucket_name must name an existing bucket in this account (replaces the %%BUCKET_NAME%%-<region> solution bucket)."
  type        = bool
  default     = true
}

variable "template_bucket_name" {
  description = "Name of the template bucket. When null and create_template_bucket is true, defaults to compliant-framework-avm-templates-<account-id>-<region>."
  type        = string
  default     = null
}

variable "template_key_prefix" {
  description = "S3 key prefix for the product template (replaces %%SOLUTION_NAME%%/%%VERSION%%/). Include a trailing slash, or set to an empty string."
  type        = string
  default     = "compliant-framework-for-federal-and-dod-workloads-in-aws-govcloud-us/v1.0.0/"
}

variable "template_bucket_force_destroy" {
  description = "Allow terraform destroy to delete the created template bucket even when it contains objects."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------------------------------------------------
# Service Catalog
# ---------------------------------------------------------------------------------------------------------------------
variable "portfolio_principal_arns" {
  description = "IAM principal (user/role/group) ARNs granted access to the portfolio. The CDK construct granted none (access was added manually in the console)."
  type        = list(string)
  default     = []
}
