# external-access-vpc

External Access VPC: IGW, 2 public subnets with NAT gateways, 2 application subnets (0.0.0.0/0 via NAT, 10.0.0.0/8 via TGW), TGW attachment subnets/route table, TGW VPC attachment, CloudWatch + S3 flow logs. No SSM parameters.

Source: `source/repositories/compliant-framework-management-services-core/templates/management-services-external-access-vpc.yml`. Called from `management-services-init.yml` with `pName=external-access`,
`pLoggingBucketArn=arn:<partition>:s3:::flow-logs-<account>-<region>` and the RAM-shared `pTransitGatewayId`.

## Inputs
| Name | Type | Default |
|---|---|---|
| name | string | "external-access" |
| vpc_cidr, instance_tenancy | string | see variables.tf |
| application_subnet_{a,b}_cidr, public_subnet_{a,b}_cidr, transit_gateway_attachment_subnet_{a,b}_cidr | string | see variables.tf |
| transit_gateway_id | string | - (TGW in the transit account, shared via RAM) |
| logging_bucket_arn | string | null -> `arn:<partition>:s3:::flow-logs-<account>-<region>` |
| tags | map(string) | {} |

CIDR/tenancy variables replace the `AWS::SSM::Parameter::Value` parameters; defaults come from
`config.json.template` (`managementServices` section), and each description names the SSM path.

## Outputs
transit_gateway_attachment_id (CFN output), vpc_id (addition)

## Differences from CloudFormation
- The VPC flow-log CloudWatch log group, flow-log IAM role had CloudFormation-generated names; Terraform uses
  `name_prefix` with `ignore_changes = [name, name_prefix]` so existing resources can be imported without replacement.
- Flow-log role policy resource is `<log group arn>:*` (identical to CFN's `LogGroup.Arn`).
- TGW attachment: `aws_ec2_transit_gateway_vpc_attachment` leaves the default route-table association/propagation
  arguments unset (they cannot be managed for RAM-shared TGWs); acceptance/routing stays in the transit account as before.
- AZs come from `data.aws_availability_zones` (state = available) `names[0]/[1]` instead of `Fn::GetAZs`.
- Deploy only when `enableExternalAccessVpc` is true (caller uses `count`).
- The public route table keeps the template's un-prefixed Name tag `public-subnet-rt`.
- IGW attachment uses `aws_internet_gateway_attachment` (separate resource, like `AWS::EC2::VPCGatewayAttachment`).
