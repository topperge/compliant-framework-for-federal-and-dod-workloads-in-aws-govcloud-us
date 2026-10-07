output "consolidated_logs_s3_bucket_arn" {
  description = "Consolidated logs bucket in the Logging account."
  value       = module.logging_assets.consolidated_logs_s3_bucket_arn
}

output "consolidated_logs_s3_bucket_cmk_arn" {
  description = "CMK of the consolidated logs bucket (also in SSM /compliant/framework/consolidated-logs/cmk/arn)."
  value       = module.logging_assets.consolidated_logs_s3_bucket_cmk_arn
}

output "logging_s3_bucket_cmk_arn" {
  description = "CMK used by CloudTrail/Config/flow-log buckets in the Logging account."
  value       = module.logging_assets.logging_s3_bucket_cmk_arn
}

output "central_guardduty_detector_id" {
  description = "GuardDuty detector in the Central account."
  value       = module.central_guardduty.detector_id
}
