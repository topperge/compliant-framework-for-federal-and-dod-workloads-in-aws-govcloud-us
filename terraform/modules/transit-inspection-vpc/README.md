# transit-inspection-vpc

Inspection VPC for the VPC-firewall design: public, firewall and TGW-attachment subnets in two AZs, IGW, two NAT
gateways, TGW attachment, flow logs and an open security group for the firewall endpoints.

Source: `source/repositories/compliant-framework-transit-core/templates/transit-inspection-vpc.yml`.

## Inputs
| Name | Type | Default |
|------|------|---------|
| name | string | "inspection" |
| transit_gateway_id | string | - |
| logging_bucket_arn | string | - |
| vpc_cidr | string | - (not in config.json.template) |
| instance_tenancy | string | default |
| public/firewall/transit_gateway_attachment_subnet_{a,b}_cidr | string | - |
| flow_log_group_name / flow_log_role_name | string | null (generated) |
| tags | map(string) | {} |

## Outputs
vpc_id, public_subnet_{a,b}_id, public_rt_{a,b}_id, firewall_subnet_{a,b}_id, firewall_rt_{a,b}_id,
transit_gateway_attachment_subnet_{a,b}_id, transit_gateway_attachment_rt_{a,b}_id, transit_gateway_attachment_id,
nat_gateway_{a,b}_id, firewall_security_group_id.

## SSM parameters written
- `/compliant/framework/transit/inspection-vpc/tgw-attach/id`

## Differences from CloudFormation
- config.json.template has no inspection-vpc values, so CIDRs are required inputs; instance_tenancy defaults to `default`.
- Flow-log log group and IAM role names: see transit-firewall-vpc.
- The security group's all-traffic ingress uses ports 0-0 (Terraform requires that for protocol -1; CFN had 0-65535, and AWS ignores ports for -1).
- The TGW VPC attachment sets default association/propagation = false explicitly.
