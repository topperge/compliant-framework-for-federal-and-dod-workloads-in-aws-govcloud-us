# management-services-assets-bucket

Environment assets bucket `environment-assets-<account>-<region>` (versioned, SSE-KMS with `alias/compliant-framework/assets/s3`,
TLS-only, GetObject/PutObject for the whole AWS Organization) and its CMK.

Source: `source/repositories/compliant-framework-management-services-core/templates/management-services-assets-bucket.yml`. In `management-services-init.yml` it was deployed only when
`pEnableDirectoryVpc` = true (the caller should apply the same `count`). Its bucket is a good `templates_bucket_name`
for the service-catalog-portfolio module (org-readable, which tenant/transit-account CloudFormation needs).

## Inputs
| Name | Type | Default |
|---|---|---|
| principal_org_id | string | - |
| tags | map(string) | {} |

## Outputs
bucket_name, bucket_arn, cmk_arn, cmk_alias_arn (the template has no Outputs; all are additions).

SSM written: `/compliant/framework/management-services/assets-bucket-cmk/arn`.

## Differences from CloudFormation
- Bucket has `prevent_destroy` (template: `DeletionPolicy: Retain`).
