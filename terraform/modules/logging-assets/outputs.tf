output "consolidated_logs_s3_bucket_arn" {
  description = "ARN of the consolidated-logs-<account>-<region> bucket (CFN oConsolidatedLogsS3BucketArn)."
  value       = aws_s3_bucket.consolidated_logs.arn
}

output "consolidated_logs_s3_bucket_cmk_arn" {
  description = "ARN of the consolidated logs CMK (CFN oConsolidatedLogsS3BucketCmkArn). Central account stores this in SSM /compliant/framework/consolidated-logs/cmk/arn."
  value       = aws_kms_key.consolidated_logs_s3_bucket_cmk.arn
}

# Additional outputs (not in the CFN template) for downstream composition

output "logging_s3_bucket_cmk_arn" {
  description = "ARN of the logging S3 CMK (alias/compliant-framework/logging/s3) used by CloudTrail and the log buckets."
  value       = aws_kms_key.logging_s3_bucket_cmk.arn
}

output "logging_s3_bucket_cmk_alias_arn" {
  description = "ARN of alias/compliant-framework/logging/s3 (cloudtrail module kms_key_id)."
  value       = aws_kms_alias.logging_s3_bucket_cmk.arn
}

output "cloudtrail_s3_bucket_name" {
  description = "Name of the cloudtrail-<account>-<region> bucket (available once its bucket policy is in place)."
  value       = aws_s3_bucket.cloudtrail.id
  depends_on  = [aws_s3_bucket_policy.cloudtrail]
}

output "config_s3_bucket_name" {
  description = "Name of the config-<account>-<region> bucket (available once its bucket policy is in place)."
  value       = aws_s3_bucket.config.id
  depends_on  = [aws_s3_bucket_policy.config]
}

output "flow_logs_s3_bucket_name" {
  description = "Name of the flow-logs-<account>-<region> bucket."
  value       = aws_s3_bucket.flow_logs.id
}
