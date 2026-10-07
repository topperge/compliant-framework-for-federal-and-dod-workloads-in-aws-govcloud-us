# security-hub

Enables Security Hub, the CIS CloudWatch metric filters (primary region) and alarms (every region) publishing to the
KMS-encrypted SNS topic `SecurityHub-CIS-Alarms` (email subscription), the IAM account password policy (primary
region) and the cross-account `SecurityHubAccessRole` (primary region, non-central accounts).
Deploy once per account per region.

Source: `source/repositories/compliant-framework-central-core/templates/security/security-hub.yml`

## Inputs
| Name | Type | Default |
|---|---|---|
| central_account_id | string | - |
| notifications_email | string | - |
| cloudtrail_cloudwatch_log_group_name | string | "" (required in primary region) |
| primary_region | string | us-gov-west-1 |
| enable_default_standards | bool | true |
| create_security_hub_access_role | bool | true |
| tags | map(string) | {} |

## Outputs
`security_hub_account_id`, `security_hub_arn`, `alarm_notification_topic_arn`, `security_hub_access_role_arn`
(CFN template has no outputs). Member invitation/acceptance (formerly the pipeline Lambda
`security_hub_invite_members`) belongs in the live layer: `aws_securityhub_member` (central provider) and
`aws_securityhub_invite_accepter` (member provider, `master_id = central_account_id`), both depending on this
module in the respective account/region.

## Differences from CloudFormation
- The `Custom::ConfigureIamPolicy` Lambda + role are replaced by `aws_iam_account_password_policy` (same settings;
  destroy deletes the policy, like the custom resource's Delete).
- Metric filters had CFN-generated names; now `CIS-<id>-<Metric>`. They will be recreated rather than imported
  unless imported by their existing names.
- `aws_securityhub_account` subscribes default standards (`enable_default_standards = true`), matching
  `AWS::SecurityHub::Hub` defaults.
- Kept as in the source (not fixed): CIS 1.1 filter emits `RootAccount` while its alarm watches `RootAccountUsage`;
  alarm name `CIS-3.8-S3BucketPolicyChanges.` has a trailing dot; the SNS CMK policy does not grant
  `cloudwatch.amazonaws.com` (so alarms cannot publish to the encrypted topic); alarms exist in non-primary regions
  without matching metric filters.
- Email subscriptions stay "pending confirmation" until confirmed; Terraform cannot delete a pending subscription.
