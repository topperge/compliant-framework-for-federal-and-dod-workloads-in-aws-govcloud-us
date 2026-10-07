# The CloudFormation template declared no Outputs; role ARNs are provided for composition.

output "role_arns" {
  description = "Map of federated role ARNs keyed by administrator_access_role / system_administrator_role / view_only_access_role."
  value       = { for k, r in aws_iam_role.federation : k => r.arn }
}
