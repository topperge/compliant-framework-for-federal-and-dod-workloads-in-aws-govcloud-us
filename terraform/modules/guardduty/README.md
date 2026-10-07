# guardduty

GuardDuty detector (15-minute finding publishing) with S3 protection. Deploy once per account per region.

Source: `source/repositories/compliant-framework-central-core/templates/security/security-guard-duty.yml`

## Inputs
| Name | Type | Default |
|---|---|---|
| finding_publishing_frequency | string | FIFTEEN_MINUTES |
| enable_s3_protection | bool | true |
| tags | map(string) | {} |

## Outputs
`detector_id` (CFN template has no outputs).

## Differences from CloudFormation
- S3 protection uses `aws_guardduty_detector_feature` (`S3_DATA_EVENTS`) instead of the deprecated
  `datasources.s3_logs` block.
