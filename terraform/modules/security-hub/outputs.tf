# The CFN template has no outputs; these support composition (e.g. aws_securityhub_member /
# aws_securityhub_invite_accepter in the live layers must depend on Security Hub being enabled).

output "security_hub_account_id" {
  description = "ID of the aws_securityhub_account resource (the AWS account ID). Reference it (or depends_on the module) before creating aws_securityhub_member / aws_securityhub_invite_accepter."
  value       = aws_securityhub_account.security_hub.id
}

output "security_hub_arn" {
  description = "ARN of the Security Hub hub in this account/region."
  value       = aws_securityhub_account.security_hub.arn
}

output "alarm_notification_topic_arn" {
  description = "ARN of the SecurityHub-CIS-Alarms SNS topic."
  value       = aws_sns_topic.security_hub_alarm_notification.arn
}

output "security_hub_access_role_arn" {
  description = "ARN of SecurityHubAccessRole (null when not created)."
  value       = one(aws_iam_role.security_hub_access[*].arn)
}
