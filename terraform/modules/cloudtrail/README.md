# cloudtrail

Organization-account multi-region CloudTrail trail delivering to the Logging account bucket
`cloudtrail-<logging_account_id>-<region>` (encrypted with `alias/compliant-framework/logging/s3` in the Logging
account) and to a CloudWatch log group (365 days) used by the CIS metric filters in `security-hub`.
Deploy in the primary region only (both Logging and Central accounts).

Source: `source/repositories/compliant-framework-central-core/templates/security/security-cloudtrail.yml`

## Inputs
| Name | Type | Default |
|---|---|---|
| logging_account_id | string | - |
| s3_bucket_name | string | null (cloudtrail-<logging>-<region>) |
| kms_key_id | string | null (logging account alias ARN) |
| trail_name | string | compliant-framework-cloudtrail |
| cloudwatch_log_group_name | string | /compliant-framework/cloudtrail |
| cloudwatch_log_group_role_name | string | CompliantFrameworkCloudTrailCloudWatchLogsRole |
| cloudwatch_log_retention_in_days | number | 365 |
| tags | map(string) | {} |

## Outputs
`cloudtrail_cloudwatch_log_group_name` (CFN `oCloudTrailCloudWatchLogGroupName`), `cloudtrail_arn`,
`cloudtrail_cloudwatch_log_group_arn`.

## Differences from CloudFormation
- The trail, log group and role had CFN-generated names; they are now variables with fixed defaults. When importing
  existing stacks set them to the existing physical names, otherwise Terraform creates new ones (and the
  security-hub metric filters follow the new log group name).
- `s3_bucket_name` / `kms_key_id` overrides were added so callers can create implicit dependencies on
  `logging-assets` outputs.
