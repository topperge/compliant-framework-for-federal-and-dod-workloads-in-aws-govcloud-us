# transit-gateway-route-tables

Configures transit gateway route table associations, propagations and static
default routes for the shared (core) VPC attachments in the transit account.

Source CFN templates (`source/repositories/compliant-framework-transit-core/templates/`):
- `transit-gateway-route-tables.yml` (wrapper, one nested stack per route table)
- `virtual-firewall/transit-gateway-route-tables-{internal,management-services,directory,external-access,firewall}.yml`
- `vpc-firewall/transit-gateway-route-tables-{internal,management-services,directory,external-access,dmz,inspection}.yml`

Run with a provider for the **transit** account.

Files: `main.tf` (resources identical in both flavours), `virtual_firewall.tf`, `vpc_firewall.tf`.

## Flavour selection (same as the CFN wrapper)
| Route table | Deployed when | Template family |
|---|---|---|
| internal, management services | always | vpc-firewall if `enable_vpc_firewall`, else virtual-firewall |
| directory | `enable_directory_vpc` | same as above |
| external access | `enable_external_access_vpc` | same as above |
| firewall | `enable_virtual_firewall` | virtual-firewall (always) |
| dmz, inspection | `enable_vpc_firewall` | vpc-firewall |

## Inputs
| Name | Type | Default | Notes |
|---|---|---|---|
| enable_virtual_firewall | bool | true | |
| enable_vpc_firewall | bool | false | |
| enable_directory_vpc | bool | true | |
| enable_external_access_vpc | bool | true | |
| attach_firewall_vpc | bool | true | `/compliant/framework/transit/firewall-vpc/tgw/attached` |
| internal_route_table_id | string | - | |
| management_services_route_table_id | string | - | |
| directory_route_table_id | string | null | |
| external_access_route_table_id | string | null | |
| firewall_route_table_id | string | null | |
| dmz_route_table_id | string | null | |
| inspection_route_table_id | string | null | |
| management_services_vpc_tgw_attachment_id | string | - | |
| directory_vpc_tgw_attachment_id | string | null | |
| external_access_vpc_tgw_attachment_id | string | null | |
| firewall_vpc_tgw_attachment_id | string | null | |
| inspection_vpc_tgw_attachment_id | string | null | |
| dmz_vpc_tgw_attachment_id | string | null | |
| tags | map(string) | {} | unused (nothing taggable) |

Preconditions fail the plan when an enabled feature lacks its ids.

## Outputs
- `firewall_family` - `"vpc-firewall"` or `"virtual-firewall"`
- `route_table_association_ids` - map of association ids (null entries when disabled)

## Differences from CloudFormation
- No nested stacks; one flat module. Resources that were identical in both
  flavours (all associations and the management/directory/external-access
  propagations) are single resources, so switching flavour only replaces the
  default routes and the firewall-VPC / inspection-VPC propagation into the
  external access route table.
- SSM-sourced values (route table ids, firewall/inspection/DMZ attachment ids,
  feature flags) are plain variables.
- The commented-out VPN default routes / VPN associations in the virtual-firewall
  templates were never deployed and are not translated, so the VPN connection id
  parameters (`/compliant/framework/transit/firewall-vpc/vpn-connection/{a,b}/id`)
  are not inputs.
- CFN outputs: none existed; two convenience outputs were added.
- Added a `terraform_data.input_validation` resource carrying plan-time preconditions.
