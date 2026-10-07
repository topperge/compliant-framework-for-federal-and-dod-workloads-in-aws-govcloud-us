# directory-vpc

Directory VPC (for Managed AD): same layout as the Management Services VPC but the endpoint security group allows only the VPC CIDR, and no SSM parameters are written.

Source: `source/repositories/compliant-framework-management-services-core/templates/management-services-directory-vpc.yml`. Called from `management-services-init.yml` with `pName=directory`,
`pLoggingBucketArn=arn:<partition>:s3:::flow-logs-<account>-<region>` and the RAM-shared `pTransitGatewayId`.

## Inputs
| Name | Type | Default |
|---|---|---|
| name | string | "directory" |
| vpc_cidr, instance_tenancy | string | see variables.tf |
| application_subnet_{a,b}_cidr, data_subnet_{a,b}_cidr, transit_gateway_attachment_subnet_{a,b}_cidr | string | see variables.tf |
| transit_gateway_id | string | - (TGW in the transit account, shared via RAM) |
| logging_bucket_arn | string | null -> `arn:<partition>:s3:::flow-logs-<account>-<region>` |
| tags | map(string) | {} |

CIDR/tenancy variables replace the `AWS::SSM::Parameter::Value` parameters; defaults come from
`config.json.template` (`managementServices` section), and each description names the SSM path.

## Outputs
vpc_id, application_subnet_a_id, application_subnet_b_id, application_rt_a, application_rt_b, data_subnet_a_id,
data_subnet_b_id, data_rt_a, data_rt_b, transit_gateway_attachment_subnet_a_id, transit_gateway_attachment_subnet_b_id,
transit_gateway_attachment_rt_id, transit_gateway_attachment_id

## Differences from CloudFormation
- The VPC flow-log CloudWatch log group, flow-log IAM role and endpoint security group had CloudFormation-generated names; Terraform uses
  `name_prefix` with `ignore_changes = [name, name_prefix]` so existing resources can be imported without replacement.
- Flow-log role policy resource is `<log group arn>:*` (identical to CFN's `LogGroup.Arn`).
- TGW attachment: `aws_ec2_transit_gateway_vpc_attachment` leaves the default route-table association/propagation
  arguments unset (they cannot be managed for RAM-shared TGWs); acceptance/routing stays in the transit account as before.
- AZs come from `data.aws_availability_zones` (state = available) `names[0]/[1]` instead of `Fn::GetAZs`.
- Deploy only when `enableDirectoryVpc` is true (caller uses `count`).
- Interface endpoints use one `for_each` resource (`aws_vpc_endpoint.interface[...]`).
