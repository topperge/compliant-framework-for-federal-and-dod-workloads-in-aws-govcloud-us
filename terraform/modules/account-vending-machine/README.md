# account-vending-machine

Account Vending Machine (AVM) for AWS GovCloud (US). Deployed in the **commercial** AWS Organizations
management (payer) account. Creates a Service Catalog portfolio *Compliant Framework - Tenant Services* with the
product *Account Vending Machine for AWS GovCloud (US)* (v1.0.0). Launching the product runs a CloudFormation
stack whose custom resources call four Lambdas that:

1. `CompliantFramework-AvmGetOu` – resolve the target OU path in the GovCloud organization,
2. `CompliantFramework-AvmCreateGovCloudAccount` – call `organizations:CreateGovCloudAccount`,
3. `CompliantFramework-AvmInviteGovCloudAccount` – invite the new account into the GovCloud organization and accept the handshake,
4. `CompliantFramework-AvmMoveAccount` – move it into the target OU.

Lambdas 1, 3 and 4 use long-term GovCloud IAM user keys read from SSM Parameter Store in this account
(the parameters are created manually; this module does not create them).

## Source
- `source/lib/account-vending-machine/account-vending-machine-construct.ts` (CDK construct, part of the
  CompliantFramework bootstrap stack; synthesized CFN in `source/test/__snapshots__/account-vending-machine-construct.test.ts.snap`)
- `source/lib/account-vending-machine/templates/compliant-framework-govcloud-account-product-v1.0.0.yml`
  -> `products/` (kept as CloudFormation; uploaded to S3 with `aws_s3_object`)
- `source/lambda/avm_*` -> `lambda/avm_*` (packaged with `archive_file` into `.build/`)

## Inputs
| Name | Type | Default |
|---|---|---|
| `tags` | map(string) | `{}` |
| `govcloud_access_key_id_parameter_name` | string | `/compliant/framework/central-avm/aws-us-gov/access-key-id` |
| `govcloud_secret_access_key_parameter_name` | string | `/compliant/framework/central-avm/aws-us-gov/secret-access-key` |
| `ssm_kms_key_arn` | string | `null` (aws/ssm key) |
| `govcloud_region` | string | `us-gov-west-1` |
| `lambda_runtime` | string | `python3.12` |
| `lambda_timeout` | number | `900` |
| `create_template_bucket` | bool | `true` |
| `template_bucket_name` | string | `null` -> `compliant-framework-avm-templates-<account>-<region>` |
| `template_key_prefix` | string | `compliant-framework-for-federal-and-dod-workloads-in-aws-govcloud-us/v1.0.0/` |
| `template_bucket_force_destroy` | bool | `false` |
| `portfolio_principal_arns` | list(string) | `[]` |

## Outputs
`portfolio_id`, `product_id`, `product_template_url`, `template_bucket_name`, `lambda_function_arns`, `lambda_role_arns`.

## Differences from CloudFormation / CDK
- Lambda runtime `python3.8` -> `python3.12` (variable); python3.8 can no longer be used for new functions.
- Lambda code: SSM parameter names and the GovCloud region are read from environment variables
  (`GOVCLOUD_ACCESS_KEY_ID_PARAMETER`, `GOVCLOUD_SECRET_ACCESS_KEY_PARAMETER`, `GOVCLOUD_REGION`) with the
  original hardcoded values as fallbacks. Otherwise unchanged; the cfn-response protocol is kept because the
  Lambdas are invoked by CloudFormation through Service Catalog.
- IAM role and inline policy names were CDK-generated; they are now `<FunctionName>-Role` and
  `<FunctionName>-DefaultPolicy`. Function names, portfolio and product names are identical.
- The product template URL (`https://%%BUCKET_NAME%%-<region>.s3.amazonaws.com/%%SOLUTION_NAME%%/%%VERSION%%/...`,
  the solution distribution bucket) is replaced by a module-created private bucket (versioned, SSE-S3, public access
  blocked, TLS-only) or an existing bucket (`create_template_bucket = false`). Uses the regional S3 endpoint.
- New optional `portfolio_principal_arns` (principal associations); CDK granted no portfolio access.
- New optional `ssm_kms_key_arn` adds `kms:Decrypt` for a CMK-encrypted SecureString.
- The product template file is unchanged. Changing its content re-uploads the object but does not create a new
  provisioning artifact; add a new versioned file/artifact for template changes.
- No CloudWatch log groups are created (same as CDK; Lambda creates `/aws/lambda/<name>`). The logs statement's
  resource (`log-group:<FunctionName>`) is kept verbatim from CDK; actual logging works via `AWSLambdaBasicExecutionRole`.
