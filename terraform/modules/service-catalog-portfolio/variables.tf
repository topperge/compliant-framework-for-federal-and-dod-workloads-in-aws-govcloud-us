variable "templates_bucket_name" {
  description = "Existing S3 bucket in this account to which the product CloudFormation templates are uploaded (replaces pS3Bucket, the environment pipeline bucket). Must be readable by Service Catalog here and by the CfnRunnerAccountAccessRole in tenant/transit accounts; the management-services-assets-bucket module's bucket (org-readable) is suitable. Written to SSM /compliant/framework/management-services/s3/environment/bucket-name."
  type        = string
}

variable "templates_s3_region" {
  description = "S3 regional endpoint label used to build template URLs https://<bucket>.<label>.amazonaws.com/... (replaces pS3Region, e.g. \"s3-us-gov-west-1\"). Defaults to \"s3.<current region>\". Written to SSM /compliant/framework/management-services/s3/region."
  type        = string
  default     = null
}

variable "upload_transit_attach_tenant_template" {
  description = "Also upload compliant-framework-transit-core/templates/transit-attach-tenant.yml (a CloudFormation template run by the product in the transit account) to the templates bucket."
  type        = bool
  default     = true
}

variable "cfn_runner_account_access_role" {
  description = "Name of the role the CfnRunner Lambda assumes in tenant/transit accounts (pCfnRunnerAccountAccessRole)."
  type        = string
  default     = "CfnRunnerAccountAccessRole"
}

variable "lambda_runtime" {
  description = "Python runtime for the CfnRunner Lambda (source template used the deprecated python3.7)."
  type        = string
  default     = "python3.12"
}

variable "portfolio_principal_arns" {
  description = "IAM principal ARNs (users/groups/roles) to associate with the portfolio. Not part of the source template."
  type        = list(string)
  default     = []
}

variable "launch_role_arn" {
  description = "Optional IAM role ARN for a LAUNCH constraint on the product. Not part of the source template."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all taggable resources."
  type        = map(string)
  default     = {}
}
