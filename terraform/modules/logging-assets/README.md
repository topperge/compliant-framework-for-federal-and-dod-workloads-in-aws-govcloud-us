# logging-assets

Central log storage for the Logging account (primary region only): logging S3 CMK, consolidated-logs CMK,
`cloudtrail-`, `config-`, `flow-logs-` buckets (each replicating into `consolidated-logs-<account>-<region>`),
the `ConsolidatedLogsReplicationRole`, and SSM parameter `/compliant/framework/logging/logging-bucket-cmk/arn`.

Source: `source/repositories/compliant-framework-central-core/templates/logging/logging-assets.yml`
(composed by `logging/logging-init.yml`, condition `cIsPrimaryRegion`).

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| principal_org_id | string | - | Organization ID allowed to use the CMKs / replicate into the consolidated bucket |
| tags | map(string) | {} | Tags |

## Outputs
`consolidated_logs_s3_bucket_arn`, `consolidated_logs_s3_bucket_cmk_arn` (CFN outputs), plus
`logging_s3_bucket_cmk_arn`, `logging_s3_bucket_cmk_alias_arn`, `cloudtrail_s3_bucket_name`,
`config_s3_bucket_name`, `flow_logs_s3_bucket_name`. The bucket name outputs depend on the bucket policies, so
passing them to the `cloudtrail` / `config` modules orders those modules correctly without module-level `depends_on`.

## Differences from CloudFormation
- The four buckets keep `DeletionPolicy: Retain` semantics via `prevent_destroy`; the KMS keys were not retained in
  CFN and have no `prevent_destroy`.
- Replication uses `aws_s3_bucket_replication_configuration` (V1 schema, no filter == CFN `Prefix: ""`) referencing
  the role resource instead of a hand-built ARN.
- No `aws_s3_bucket_ownership_controls` (CFN set none). Buckets created new by Terraform get the AWS default
  `BucketOwnerEnforced`; the `s3:x-amz-acl = bucket-owner-full-control` conditions still work with it.
- The `/compliant/framework/consolidated-logs/cmk/arn` SSM parameter written by `central-init.yml` lives in the
  Central account and is NOT in this module (see the live layer).
