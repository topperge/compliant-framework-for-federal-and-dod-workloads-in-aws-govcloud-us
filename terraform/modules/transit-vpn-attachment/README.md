# transit-vpn-attachment

Two customer gateways and two BGP IPsec VPN connections from the transit gateway to the virtual firewall appliances.

Source: `source/repositories/compliant-framework-transit-core/templates/transit-vpn-attachment.yml`, plus `/compliant/framework/transit/firewall-vpc/vpn-connection/{a,b}/id`
from `source/repositories/compliant-framework-transit-core/templates/transit-init.yml`.

## Inputs
| Name | Type | Default |
|------|------|---------|
| name | string | "firewall" |
| transit_gateway_id | string | - |
| customer_gateway_{a,b}_ip_address | string | - (transit-firewall-vpc firewall_{a,b}_internal_eni_public_ip_address) |
| customer_gateway_a_bgp_asn / customer_gateway_b_bgp_asn | string | "65200" / "65210" |
| tags | map(string) | {} |

## Outputs
firewall_vpn_connection_a_id, firewall_vpn_connection_b_id,
firewall_vpn_connection_{a,b}_transit_gateway_attachment_id.

## SSM parameters written
- `/compliant/framework/transit/firewall-vpc/vpn-connection/a/id`
- `/compliant/framework/transit/firewall-vpc/vpn-connection/b/id`

## Differences from CloudFormation
- The VPN-id SSM parameters moved here from transit-init.yml. When the virtual firewall is disabled the module
  isn't instantiated, so they're absent (CFN wrote `no-value`).
- Extra outputs: the VPN connections' TGW attachment ids.
