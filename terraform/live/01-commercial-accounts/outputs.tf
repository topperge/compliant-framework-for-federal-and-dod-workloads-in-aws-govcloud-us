output "govcloud_accounts" {
  description = "Created account pairs keyed like commercial.govcloud_accounts in the config. Copy the govcloud_id values into the GovCloud sections of the config."
  value = {
    for k, a in aws_organizations_account.govcloud : k => {
      name          = a.name
      commercial_id = a.id
      govcloud_id   = a.govcloud_id
    }
  }
}

output "govcloud_accounts_ou_id" {
  description = "Commercial OU holding the commercial twins of the GovCloud accounts."
  value       = aws_organizations_organizational_unit.govcloud_accounts.id
}
