output "cloudtrail_arn" {
  description = "Account CloudTrail trail."
  value       = module.security_baseline.cloudtrail_arn
}

output "guardduty_detector_id" {
  description = "Account GuardDuty detector."
  value       = module.security_baseline.guardduty_detector_id
}
