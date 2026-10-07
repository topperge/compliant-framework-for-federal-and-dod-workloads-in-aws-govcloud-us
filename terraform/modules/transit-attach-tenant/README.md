# transit-attach-tenant

Associates a tenant (or plugin) VPC's transit gateway attachment with the
internal TGW route table and propagates it into the management services,
inspection / firewall, directory and external access route tables according to
the enable flags.

Source CFN template: `source/repositories/compliant-framework-transit-core/templates/transit-attach-tenant.yml`
(used by plugin `-tgw-attachment` pipeline actions and the Service Catalog
`tenant-two-tier-vpc` product via the CfnRunner custom resource).

Run with a provider for the **transit** account (TGW owner).

## Inputs
| Name | Type | Default |
|---|---|---|
| tgw_attachment_id | string | - |
| enable_virtual_firewall | bool | true |
| enable_vpc_firewall | bool | false |
| enable_directory_vpc | bool | true |
| enable_external_access_vpc | bool | true |
| internal_route_table_id | string | - |
| management_services_route_table_id | string | - |
| directory_route_table_id | string | null |
| firewall_route_table_id | string | null |
| inspection_route_table_id | string | null |
| external_access_route_table_id | string | null |
| tags | map(string) | {} (unused) |

## Outputs
- `route_table_association_id`
- `propagated_route_table_ids`

## Differences from CloudFormation
- SSM-sourced flags and route table ids are plain variables.
- The pipeline passed `xxxxxx` placeholders for disabled route tables; here they
  default to `null` and preconditions require them only when the feature is enabled.
- The pipeline deployed the plugin variant into the plugin account
  (`action.environments[env].accountId`) although TGW route table
  associations/propagations can only be made by the TGW owner; this module
  must be applied in the transit account (as the Service Catalog path already did).
- No CFN outputs existed; two convenience outputs were added.
