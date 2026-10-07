# The CloudFormation template declared no Outputs; these are provided for composition in the live layer.

output "cloudtrail_arn" {
  description = "ARN of the account's multi-region CloudTrail trail."
  value       = aws_cloudtrail.cloudtrail.arn
}

output "cloudtrail_log_group_name" {
  description = "CloudWatch log group receiving CloudTrail events."
  value       = aws_cloudwatch_log_group.cloudtrail_cloudwatch_log_group.name
}

output "security_hub_alarm_notification_topic_arn" {
  description = "ARN of the SecurityHub-CIS-Alarms SNS topic."
  value       = aws_sns_topic.security_hub_alarm_notification_topic.arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector id in this account/region."
  value       = aws_guardduty_detector.guard_duty_detector.id
}

output "security_hub_access_role_arn" {
  description = "ARN of SecurityHubAccessRole (assumed from the central account to accept Security Hub invitations)."
  value       = aws_iam_role.security_hub_access_role.arn
}

output "config_recorder_name" {
  description = "Name of the AWS Config configuration recorder."
  value       = aws_config_configuration_recorder.config_configuration_recorder.name
}
