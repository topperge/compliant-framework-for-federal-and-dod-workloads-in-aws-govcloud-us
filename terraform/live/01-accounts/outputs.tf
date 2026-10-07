output "accounts" {
  description = "Created accounts keyed like commercial.accounts in the config. `account_id` is the id to copy into the central/logging/environments sections (the GovCloud id when partition is aws-us-gov)."
  value = {
    for k, a in aws_organizations_account.this : k => {
      name          = a.name
      commercial_id = a.id
      govcloud_id   = a.govcloud_id
      account_id    = local.is_govcloud ? a.govcloud_id : a.id
    }
  }
}

output "govcloud_accounts_ou_id" {
  description = "Commercial OU holding the commercial twins of the GovCloud accounts (null when partition is aws)."
  value       = one(aws_organizations_organizational_unit.govcloud_accounts[*].id)
}
