# config

AWS Config recorder + delivery channel (delivering to `config-<logging_account_id>-<primary_region>`), `ConfigRole`
(primary region only, global IAM) and, in the Central account's primary region only, the organization aggregator
`config-aggregator`. Deploy once per account per region (Logging and Central accounts; primary region first).

Source: `source/repositories/compliant-framework-central-core/templates/security/security-config.yml`

## Inputs
| Name | Type | Default |
|---|---|---|
| central_account_id | string | - |
| logging_account_id | string | - |
| primary_region | string | us-gov-west-1 |
| config_delivery_frequency | string | Three_Hours |
| delivery_s3_bucket_name | string | null (config-<logging>-<primary_region>) |
| configuration_recorder_name | string | default |
| delivery_channel_name | string | default |
| config_role_managed_policy_name | string | AWSConfigRole |
| config_aggregator_role_name | string | CompliantFrameworkConfigAggregatorRole |
| tags | map(string) | {} |

Conditions (primary region / central account) are derived from `data.aws_region` / `data.aws_caller_identity`;
do not wrap the module in `depends_on` (it defers those data sources and makes `count` unknown) - pass
`delivery_s3_bucket_name = module.logging_assets.config_s3_bucket_name` instead.

## Outputs
`configuration_recorder_name`, `config_role_arn`, `config_aggregator_arn` (CFN template has no outputs).

## Differences from CloudFormation
- Added `aws_config_configuration_recorder_status` (enabled) - CFN starts the recorder implicitly.
- Recorder, delivery channel and aggregator role had CFN-generated names; now variables (set to existing names for import).
- `AWSConfigRole` is a deprecated AWS managed policy; kept as default for parity, override with `AWS_ConfigRole`
  if attachment is refused.
