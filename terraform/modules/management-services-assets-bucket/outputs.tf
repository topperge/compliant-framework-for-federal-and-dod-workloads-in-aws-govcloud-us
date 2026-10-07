# The source template defines no Outputs; these are provided for composition.

output "bucket_name" {
  description = "Name of the environment-assets-<account>-<region> bucket."
  value       = aws_s3_bucket.s3_bucket.id
}

output "bucket_arn" {
  description = "ARN of the environment-assets-<account>-<region> bucket."
  value       = aws_s3_bucket.s3_bucket.arn
}

output "cmk_arn" {
  description = "ARN of the assets CMK (also in SSM /compliant/framework/management-services/assets-bucket-cmk/arn)."
  value       = aws_kms_key.s3_bucket_cmk.arn
}

output "cmk_alias_arn" {
  description = "ARN of alias/compliant-framework/assets/s3."
  value       = aws_kms_alias.s3_bucket_cmk.arn
}
