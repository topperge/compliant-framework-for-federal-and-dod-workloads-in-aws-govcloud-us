output "firewall_vpn_connection_a_id" {
  description = "Firewall VPN connection A id."
  value       = aws_vpn_connection.vpn_connection_a.id
}

output "firewall_vpn_connection_b_id" {
  description = "Firewall VPN connection B id."
  value       = aws_vpn_connection.vpn_connection_b.id
}

output "firewall_vpn_connection_a_transit_gateway_attachment_id" {
  description = "TGW attachment id of VPN connection A (not in the CFN outputs; needed for TGW route-table associations)."
  value       = aws_vpn_connection.vpn_connection_a.transit_gateway_attachment_id
}

output "firewall_vpn_connection_b_transit_gateway_attachment_id" {
  description = "TGW attachment id of VPN connection B (not in the CFN outputs; needed for TGW route-table associations)."
  value       = aws_vpn_connection.vpn_connection_b.transit_gateway_attachment_id
}
