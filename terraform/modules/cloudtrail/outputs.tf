output "cloudtrail_cloudwatch_log_group_name" {
  description = "Name of the CloudTrail CloudWatch log group (CFN oCloudTrailCloudWatchLogGroupName); pass to the security-hub module."
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

# Additional outputs (not in the CFN template)

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.cloudtrail.arn
}

output "cloudtrail_cloudwatch_log_group_arn" {
  description = "ARN of the CloudTrail CloudWatch log group."
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}
