# The CFN template has no outputs; these support composition.

output "configuration_recorder_name" {
  description = "Name of the AWS Config configuration recorder."
  value       = aws_config_configuration_recorder.config.name
}

output "config_role_arn" {
  description = "ARN of ConfigRole (created only in the primary region, referenced by name elsewhere)."
  value       = local.config_role_arn
}

output "config_aggregator_arn" {
  description = "ARN of the organization config aggregator (null unless central account + primary region)."
  value       = one(aws_config_configuration_aggregator.config[*].arn)
}
