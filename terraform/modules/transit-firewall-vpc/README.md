# transit-firewall-vpc

Virtual firewall (VDSS) VPC in the Transit account: external/internal/management/TGW-attachment subnets in two AZs,
optional IGW + NAT gateways, optional TGW attachment, flow logs (CloudWatch + S3), and the ENIs/EIPs for the
third-party firewall appliances.

Source: `source/repositories/compliant-framework-transit-core/templates/transit-firewall-vpc.yml`, plus `/compliant/framework/transit/firewall-vpc/tgw-attach/id` from
`source/repositories/compliant-framework-transit-core/templates/transit-init.yml`.

## Inputs
| Name | Type | Default |
|------|------|---------|
| name | string | "firewall" |
| transit_gateway_id | string | - |
| logging_bucket_arn | string | - |
| vpc_cidr | string | 10.0.0.0/21 |
| vpc_nipr_cidr | string | 0.0.0.0/0 (= none) |
| instance_tenancy | string | default |
| enable_igw / attach_tgw | bool | true / true |
| external/internal/management/transit_gateway_attachment_subnet_{a,b}_cidr | string | config.json.template values |
| flow_log_group_name / flow_log_role_name | string | null (generated) |
| tags | map(string) | {} |

## Outputs
vpc_id, internal_subnet_{a,b}_id, internal_rt_id, external_subnet_{a,b}_id, external_rt_{a,b}_id,
management_subnet_{a,b}_id, management_rt_id, firewall_{a,b}_external_eni_id,
firewall_{a,b}_external_eni_private_ip_address, firewall_{a,b}_internal_eni_id,
firewall_{a,b}_internal_eni_private_ip_address, firewall_{a,b}_internal_eni_public_ip_address,
firewall_{a,b}_management_eni_id, firewall_{a,b}_management_eni_private_ip_address,
firewall_vpc_transit_gateway_attachment_id, transit_gateway_attachment_rt_{a,b}_id.

## SSM parameters written
- `/compliant/framework/transit/firewall-vpc/tgw-attach/id` (attachment id, or `no-value` when attach_tgw = false)

## Differences from CloudFormation
- The flow-log log group and IAM role had CloudFormation-generated names; here they use a `name_prefix`
  unless `flow_log_group_name` / `flow_log_role_name` are set (set them to the existing names to import).
- `firewall_vpc_transit_gateway_attachment_id` output is `null` (CFN: `no-value`) when attach_tgw = false; the SSM parameter keeps `no-value`.
- When the virtual firewall is disabled the live layer doesn't instantiate this module, so the tgw-attach SSM parameter
  is absent (CFN wrote `no-value`). Only virtual-firewall route-table stacks read it.
- The TGW VPC attachment sets `transit_gateway_default_route_table_association/propagation = false` explicitly (the TGW has defaults disabled).
- Extra outputs: transit_gateway_attachment_rt_{a,b}_id.
