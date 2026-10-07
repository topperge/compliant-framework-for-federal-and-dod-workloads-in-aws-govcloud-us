# The source template defines no Outputs; these are provided for composition.

output "logging_s3_bucket_cmk_arn" {
  description = "ARN of the logging S3 CMK (also in SSM /compliant/framework/management-services/logging-bucket-cmk/arn)."
  value       = aws_kms_key.logging_s3_bucket_cmk.arn
}

output "logging_s3_bucket_cmk_alias_arn" {
  description = "ARN of alias/compliant-framework/logging/s3."
  value       = aws_kms_alias.logging_s3_bucket_cmk.arn
}

output "cloudtrail_bucket_name" {
  description = "Name of the cloudtrail-<account>-<region> bucket."
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the cloudtrail-<account>-<region> bucket."
  value       = aws_s3_bucket.cloudtrail.arn
}

output "config_bucket_name" {
  description = "Name of the config-<account>-<region> bucket."
  value       = aws_s3_bucket.config.id
}

output "config_bucket_arn" {
  description = "ARN of the config-<account>-<region> bucket."
  value       = aws_s3_bucket.config.arn
}

output "flow_logs_bucket_name" {
  description = "Name of the flow-logs-<account>-<region> bucket."
  value       = aws_s3_bucket.flow_logs.id
}

output "flow_logs_bucket_arn" {
  description = "ARN of the flow-logs-<account>-<region> bucket (pass as logging_bucket_arn to the VPC modules)."
  value       = aws_s3_bucket.flow_logs.arn
}

output "consolidated_logs_replication_role_arn" {
  description = "ARN of the ConsolidatedLogsReplicationRole IAM role."
  value       = aws_iam_role.consolidated_logs_replication.arn
}
