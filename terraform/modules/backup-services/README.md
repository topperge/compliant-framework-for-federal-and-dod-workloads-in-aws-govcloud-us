# backup-services

AWS Backup for one account: `BackupAdmin` service role, a CMK, the `standard` vault, a backup plan with daily /
weekly / monthly rules, and a tag-based selection (`BackupPolicy = standard`).

Source: `source/repositories/compliant-framework-security-baseline/templates/backup-services.yml`
(formerly a service-managed StackSet per environment OU; instantiate once per member account).

## Inputs

| Name | Type | Default |
|------|------|---------|
| backup_admin_role_name | string | `BackupAdmin` |
| backup_tag_key | string | `BackupPolicy` |
| backup_cancel_minutes | number | `240` |
| backup_completion_minutes | number | `720` |
| backup_policy1_name | string | `standard` |
| backup_policy1_vault_name | string | `standard` |
| backup_policy1_days / _weeks / _months | number (nullable) | `14` / `42` / `365` |
| backup_policy1_to_cold_store_days | number (nullable) | `60` |
| backup_policy1_tag_value | string | `standard` |
| backup_policy1_daily/weekly/monthly_schedule | string | `(0 9 * * ? *)` / `(0 9 ? * SUN *)` / `(0 9 1 * ? *)` |
| tags | map(string) | `{}` |

## Outputs

`aws_backup_automation_role` (role name), `backup_policy1` (plan id), `backup_policy1_vault` (vault name).

## Differences from CloudFormation

- Empty-string parameters that disabled lifecycle/cold storage (`cPolicy1*` conditions) are `null` numbers.
- The selection's role ARN references the role resource instead of being built from the role name.
- The KMS key has no alias in either version.
