# security-baseline

Single-account security baseline: CloudTrail (multi-region, delivered to the management-services account bucket),
AWS Config recorder/delivery channel, Security Hub, GuardDuty, IAM password policy, CIS 1.1/3.x log metric filters
and alarms with an encrypted SNS topic, cross-account access roles, and the "Operational Best Practices for CMMC
Level 5" AWS managed Config rules.

Source: `source/repositories/compliant-framework-security-baseline/templates/security-baseline.yml`
(formerly a service-managed StackSet per environment OU; instantiate once per member account).

## Inputs

| Name | Type | Default |
|------|------|---------|
| central_account_id | string | required |
| management_services_account_id | string | required |
| notifications_email | string | required |
| config_delivery_frequency | string | `Three_Hours` |
| cloudtrail_name | string | `compliant-framework-security-baseline` |
| cloudtrail_log_group_name | string | `null` (generated) |
| config_recorder_name | string | `default` |
| config_delivery_channel_name | string | `default` |
| tags | map(string) | `{}` |

## Outputs

`cloudtrail_arn`, `cloudtrail_log_group_name`, `security_hub_alarm_notification_topic_arn`, `guardduty_detector_id`,
`security_hub_access_role_arn`, `config_recorder_name` (the CFN template had no Outputs).

## Differences from CloudFormation

- `Custom::ConfigureIamPolicy` (+ its Lambda `rConfigureIamPolicyFunction` and role `rConfigureIamPolicyRole`) is
  replaced by `aws_iam_account_password_policy` with identical settings. On destroy, Terraform deletes the password
  policy (same as the custom resource's Delete).
- `aws_config_configuration_recorder_status` added: CloudFormation starts the recorder implicitly.
- GuardDuty S3 logs enabled via `aws_guardduty_detector_feature` (`S3_DATA_EVENTS`) instead of the deprecated
  `datasources` block.
- Names CloudFormation generated (trail, log group, Config recorder/channel, CloudTrail/Config role names, metric
  filter names) are variables or Terraform-generated; set the variables to the existing physical names when importing.
  Metric filters are named after their metric name (e.g. `RootAccountUsage`).
- CIS metric filters/alarms, Config rules and central access roles use `for_each` (keys = snake_case logical id or
  ConfigRuleName). Conditions `cIsNotGovCloud` / `cIsNotGovCloudEast1` are derived from the provider region.
- Kept as-is from the source (likely bugs): alarm `CIS-1.1-RootAccountUsage` watches metric `RootAccountUsage`, not
  `RootAccount`; alarm name `CIS-3.8-S3BucketPolicyChanges.` has a trailing dot; the SNS CMK policy grants
  CloudTrail (not CloudWatch/SNS) use of the key, so alarm notifications to the encrypted topic may fail.
