# The CFN template has no outputs; exposed for composition.

output "administrators_access_role_arn" {
  description = "ARN of CompliantFrameworkAdministratorsAccessRole."
  value       = aws_iam_role.administrators_access.arn
}

output "security_auditors_access_role_arn" {
  description = "ARN of CompliantFrameworkSecurityAuditorsAccessRole."
  value       = aws_iam_role.security_auditors_access.arn
}

output "view_only_access_role_arn" {
  description = "ARN of CompliantFrameworkViewOnlyAccessRole."
  value       = aws_iam_role.view_only_access.arn
}

output "group_names" {
  description = "Names of the IAM groups (administrators, security_auditors, view_only)."
  value = {
    administrators    = aws_iam_group.administrators.name
    security_auditors = aws_iam_group.security_auditors.name
    view_only         = aws_iam_group.view_only.name
  }
}
