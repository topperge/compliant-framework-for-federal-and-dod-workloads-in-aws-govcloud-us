# transit-dmz-vpc

DMZ VPC for the VPC-firewall design: public and TGW-attachment subnets in two AZs, IGW, TGW attachment, flow logs,
and a RAM share of the public subnets to the organization.

Source: `source/repositories/compliant-framework-transit-core/templates/transit-dmz-vpc.yml`.

## Inputs
| Name | Type | Default |
|------|------|---------|
| name | string | "dmz" |
| transit_gateway_id | string | - |
| logging_bucket_arn | string | - |
| central_account_id / principal_org_id | string | - |
| vpc_cidr | string | - (not in config.json.template) |
| instance_tenancy | string | default |
| public_subnet_{a,b}_cidr, transit_gateway_attachment_subnet_{a,b}_cidr | string | - |
| flow_log_group_name / flow_log_role_name | string | null (generated) |
| tags | map(string) | {} |

## Outputs
vpc_id, public_subnet_a_id, public_subnet_b_id, public_rt_id, transit_gateway_attachment_rt_id, transit_gateway_attachment_id.

## SSM parameters written
- `/compliant/framework/transit/dmz-vpc/tgw-attach/id`

## Differences from CloudFormation
- config.json.template has no dmz-vpc values, so CIDRs are required inputs; instance_tenancy defaults to `default`.
- Flow-log log group and IAM role names: see transit-firewall-vpc.
- The RAM share is split into share + resource associations + principal association.
- The TGW VPC attachment sets default association/propagation = false explicitly.
