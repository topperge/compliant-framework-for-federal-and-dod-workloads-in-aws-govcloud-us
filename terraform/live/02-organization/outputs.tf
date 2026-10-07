output "organization_id" {
  description = "GovCloud organization id."
  value       = aws_organizations_organization.this.id
}

output "root_id" {
  description = "GovCloud organization root id."
  value       = aws_organizations_organization.this.roots[0].id
}

output "core_accounts_ou_id" {
  description = "OU holding the core (logging) account."
  value       = aws_organizations_organizational_unit.core_accounts.id
}

output "environment_ou_ids" {
  description = "Environment OU id per environment (transit and management-services accounts)."
  value       = { for k, ou in aws_organizations_organizational_unit.environment : k => ou.id }
}

output "tenant_ou_ids" {
  description = "Tenant OU id per environment."
  value       = { for k, ou in aws_organizations_organizational_unit.tenants : k => ou.id }
}
