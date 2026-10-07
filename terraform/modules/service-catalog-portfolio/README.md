# service-catalog-portfolio

Service Catalog portfolio "Compliant Framework - Tenant Services" with the "Two Tier VPC" product (v1.0.0), the
`CompliantFramework-CfnRunner` Lambda (+ `CompliantFrameworkCfnRunnerRole`) that backs the product's custom resources,
the product template uploads, and the two SSM parameters the product template reads.

Source: `source/repositories/compliant-framework-management-services-core/templates/service-catalog/portfolio.yml`; product artifacts from `source/repositories/compliant-framework-management-services-core/templates/service-catalog/tenant-services/**`.

## Product artifacts stay CloudFormation
A `CLOUD_FORMATION_TEMPLATE` product *is* a CloudFormation template, so these files are copied **unchanged** into `products/`:
- `products/tenant-two-tier-vpc/V1.0.0/tenant-two-tier-vpc-product.yml` (provisioning artifact; custom resources call the CfnRunner Lambda)
- `products/tenant-two-tier-vpc/V1.0.0/tenant-two-tier-vpc.yml` (stack the Lambda creates in the tenant account)
- `products/transit-attach-tenant.yml` (copy of `compliant-framework-transit-core/templates/transit-attach-tenant.yml`; stack the
  Lambda creates in the transit account; upload toggled by `upload_transit_attach_tenant_template`)

They are uploaded with `aws_s3_object` to the **existing** bucket `templates_bucket_name` under the same keys the old pipeline used
(`compliant-framework-management-services-core/templates/...`, `compliant-framework-transit-core/templates/...`) because the product
template hard-codes those paths and builds URLs from SSM `/compliant/framework/management-services/s3/{environment/bucket-name,region}`.

Why a passed-in bucket: it is the simplest drop-in for the old pipeline bucket (`pS3Bucket`) and avoids a second bucket with its own
cross-account policy. The bucket must be in this provider's account and readable by Service Catalog here and by
`CfnRunnerAccountAccessRole` in tenant/transit accounts (CloudFormation fetches TemplateURL with the caller's credentials).
The `management-services-assets-bucket` bucket satisfies this (org-wide GetObject, org-usable CMK).

## Inputs
| Name | Type | Default |
|---|---|---|
| templates_bucket_name | string | - |
| templates_s3_region | string | null -> `s3.<region>` |
| upload_transit_attach_tenant_template | bool | true |
| cfn_runner_account_access_role | string | "CfnRunnerAccountAccessRole" |
| lambda_runtime | string | "python3.12" |
| portfolio_principal_arns | list(string) | [] |
| launch_role_arn | string | null |
| tags | map(string) | {} |

## Outputs
portfolio_id, tenant_two_tier_vpc_product_id, cfn_runner_lambda_arn, cfn_runner_role_arn, product_template_url
(the template has no Outputs; all are additions).

SSM written: `/compliant/framework/management-services/s3/environment/bucket-name`, `/compliant/framework/management-services/s3/region`.

## Differences from CloudFormation
- Lambda code extracted to `lambda/cfn_runner/index.py`, packaged with `archive_file`. CFN `!Sub` values (partition, access role
  name) became env vars `PARTITION` / `CFN_RUNNER_ACCOUNT_ACCESS_ROLE`. It still speaks the cfn-response protocol (it is invoked by
  CloudFormation at product launch), so a minimal `cfnresponse.py` is vendored (Lambda only injects it for inline ZipFile code).
- Runtime python3.7 (deprecated) -> `var.lambda_runtime` (python3.12).
- `pS3Bucket`/`pS3Region` -> `templates_bucket_name`/`templates_s3_region`. The old pipeline value was `s3-<region>`; the default
  here is `s3.<region>` (both resolve). Set `templates_s3_region = "s3-us-gov-west-1"` to keep the old SSM value exactly.
- New, optional (absent in source): principal portfolio associations and a LAUNCH constraint.
- Lambda permission gets an explicit `statement_id` (`AllowCloudFormationInvoke`).
- Known source quirk, kept unchanged: the product's `ServiceToken` is `arn:<partition>:lambda:<region>:function:CompliantFramework-CfnRunner`
  (no account id).
