# management-services-logging

Logging assets for a Management Services account: logging S3 CMK (`alias/compliant-framework/logging/s3`),
the `cloudtrail-`, `config-` and `flow-logs-<account>-<region>` buckets (versioned, SSE-KMS, replicated to
`consolidated-logs-<logging account>-<primary region>`), their bucket policies and `ConsolidatedLogsReplicationRole`.

Source: `source/repositories/compliant-framework-management-services-core/templates/management-services-logging.yml` (nested-stack wrapper, no resources of its own) and
`source/repositories/compliant-framework-management-services-core/templates/management-services-logging-assets.yml`. Deploy before the VPC modules (they send flow logs to `flow-logs-*`).

## Inputs
| Name | Type | Default | Notes |
|---|---|---|---|
| principal_org_id | string | - | Org allowed to use the CMK |
| logging_account_id | string | - | Owner of the consolidated logs bucket |
| consolidated_logs_s3_bucket_cmk_arn | string | - | Was SSM `/compliant/framework/consolidated-logs/cmk/arn` (central acct) |
| primary_region | string | - | config.json `core.primaryRegion` |
| tags | map(string) | {} | |

## Outputs
logging_s3_bucket_cmk_arn, logging_s3_bucket_cmk_alias_arn, cloudtrail_bucket_name, cloudtrail_bucket_arn,
config_bucket_name, config_bucket_arn, flow_logs_bucket_name, flow_logs_bucket_arn, consolidated_logs_replication_role_arn
(the template has no Outputs; all are additions).

SSM written: `/compliant/framework/management-services/logging-bucket-cmk/arn`.

## Differences from CloudFormation
- Buckets have `prevent_destroy` (template: `DeletionPolicy: Retain`). The KMS key was not retained and has no guard.
- Replication uses `aws_s3_bucket_replication_configuration` with no `filter` (legacy V1 schema, empty prefix) to match the
  template's `Prefix: ""` rule (delete markers replicated as in V1). It explicitly depends on versioning.
- The template referenced the replication role by constructed ARN; here it references `aws_iam_role` directly.
