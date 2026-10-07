# transit-gateway

Transit gateway for an environment's Transit account, its TGW route tables, a RAM share of the TGW to the
organization, and the SSM parameters other stacks read.

Source: `source/repositories/compliant-framework-transit-core/templates/transit-gateway.yml`, plus the four `/compliant/framework/transit/*/enabled` SSM parameters
from `source/repositories/compliant-framework-transit-core/templates/transit-init.yml`.

## Inputs
| Name | Type | Default |
|------|------|---------|
| transit_gateway_amazon_side_asn | number | 65224 |
| central_account_id | string | - |
| principal_org_id | string | - |
| enable_directory_vpc / enable_external_access_vpc / enable_vpc_firewall / enable_virtual_firewall | bool | false |
| tags | map(string) | {} |

## Outputs
transit_gateway_id, transit_gateway_arn, transit_gateway_internal_route_table_id,
transit_gateway_management_services_route_table_id, transit_gateway_directory_route_table_id,
transit_gateway_external_access_route_table_id, transit_gateway_firewall_route_table_id,
transit_gateway_dmz_route_table_id, transit_gateway_inspection_route_table_id, resource_share_arn.
Conditional route-table outputs are `null` when disabled.

## SSM parameters written
- `/compliant/framework/transit/transit-gateway/id`
- `/compliant/framework/transit/transit-gateway/{internal,management-services,directory,external-access,firewall,dmz,inspection}-route-table/id`
  (disabled tables hold `xxxxxx`, as in CFN)
- `/compliant/framework/transit/{directory-vpc,external-access-vpc,vpc-firewall,virtual-firewall}/enabled` (`true`/`false`; from transit-init.yml)

## Differences from CloudFormation
- `AWS::RAM::ResourceShare` is split into `aws_ram_resource_share` + `aws_ram_resource_association` + `aws_ram_principal_association`.
- TGW settings are identical (`auto_accept_shared_attachments = enable`, default association/propagation disabled),
  so cross-account VPC attachments are auto-accepted, as before.
- The enabled-flag SSM parameters moved here from the transit-init wrapper.
- Extra convenience outputs: transit_gateway_arn, resource_share_arn.
