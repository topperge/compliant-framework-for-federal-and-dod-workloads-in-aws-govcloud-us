# management-services-vpc

Management Services VPC: 2-AZ application/data/TGW-attachment subnets, per-subnet route tables, TGW VPC attachment with 0.0.0.0/0 from the application route tables to the TGW, CloudWatch + S3 flow logs, interface endpoints (ssm, ssmmessages, ec2messages, elasticfilesystem) with an RFC1918 security group, S3 gateway endpoint, and 13 SSM parameters under `/compliant/framework/management-services/management-services-vpc/`.

Source: `source/repositories/compliant-framework-management-services-core/templates/management-services-vpc.yml`. Called from `management-services-init.yml` with `pName=management-services`,
`pLoggingBucketArn=arn:<partition>:s3:::flow-logs-<account>-<region>` and the RAM-shared `pTransitGatewayId`.

## Inputs
| Name | Type | Default |
|---|---|---|
| name | string | "management-services" |
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
- SSM parameter names are kept verbatim, including the template's quirk of storing the TGW **attachment id** under `.../tgw-attach-subnet/route-table/b/id`.
- Interface endpoints use one `for_each` resource (`aws_vpc_endpoint.interface["ssm"|"ssmmessages"|"ec2messages"|"efs"]`).
- Security group rules are inline; each protocol block lists the three RFC1918 CIDRs (same effective rules).
