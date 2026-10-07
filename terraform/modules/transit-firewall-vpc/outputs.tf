output "vpc_id" {
  description = "Firewall VPC id."
  value       = aws_vpc.vpc.id
}

output "internal_subnet_a_id" {
  description = "Internal subnet A id."
  value       = aws_subnet.internal_subnet_a.id
}

output "internal_subnet_b_id" {
  description = "Internal subnet B id."
  value       = aws_subnet.internal_subnet_b.id
}

output "internal_rt_id" {
  description = "Internal route table id."
  value       = aws_route_table.internal_rt.id
}

output "external_subnet_a_id" {
  description = "External subnet A id."
  value       = aws_subnet.external_subnet_a.id
}

output "external_subnet_b_id" {
  description = "External subnet B id."
  value       = aws_subnet.external_subnet_b.id
}

output "external_rt_a_id" {
  description = "External route table A id."
  value       = aws_route_table.external_rt_a.id
}

output "external_rt_b_id" {
  description = "External route table B id."
  value       = aws_route_table.external_rt_b.id
}

output "management_subnet_a_id" {
  description = "Management subnet A id."
  value       = aws_subnet.management_subnet_a.id
}

output "management_subnet_b_id" {
  description = "Management subnet B id."
  value       = aws_subnet.management_subnet_b.id
}

output "management_rt_id" {
  description = "Management route table id."
  value       = aws_route_table.management_rt.id
}

output "firewall_a_external_eni_id" {
  description = "Firewall A external ENI id."
  value       = aws_network_interface.firewall_a_external_eni.id
}

output "firewall_a_external_eni_private_ip_address" {
  description = "Firewall A external ENI primary private IP."
  value       = aws_network_interface.firewall_a_external_eni.private_ip
}

output "firewall_b_external_eni_id" {
  description = "Firewall B external ENI id."
  value       = aws_network_interface.firewall_b_external_eni.id
}

output "firewall_b_external_eni_private_ip_address" {
  description = "Firewall B external ENI primary private IP."
  value       = aws_network_interface.firewall_b_external_eni.private_ip
}

output "firewall_a_internal_eni_id" {
  description = "Firewall A internal ENI id."
  value       = aws_network_interface.firewall_a_internal_eni.id
}

output "firewall_a_internal_eni_private_ip_address" {
  description = "Firewall A internal ENI primary private IP."
  value       = aws_network_interface.firewall_a_internal_eni.private_ip
}

output "firewall_a_internal_eni_public_ip_address" {
  description = "Firewall A internal ENI Elastic IP (used as VPN customer gateway A address)."
  value       = aws_eip.firewall_a_internal_eip.public_ip
}

output "firewall_b_internal_eni_id" {
  description = "Firewall B internal ENI id."
  value       = aws_network_interface.firewall_b_internal_eni.id
}

output "firewall_b_internal_eni_private_ip_address" {
  description = "Firewall B internal ENI primary private IP."
  value       = aws_network_interface.firewall_b_internal_eni.private_ip
}

output "firewall_b_internal_eni_public_ip_address" {
  description = "Firewall B internal ENI Elastic IP (used as VPN customer gateway B address)."
  value       = aws_eip.firewall_b_internal_eip.public_ip
}

output "firewall_a_management_eni_id" {
  description = "Firewall A management ENI id."
  value       = aws_network_interface.firewall_a_management_eni.id
}

output "firewall_a_management_eni_private_ip_address" {
  description = "Firewall A management ENI primary private IP."
  value       = aws_network_interface.firewall_a_management_eni.private_ip
}

output "firewall_b_management_eni_id" {
  description = "Firewall B management ENI id."
  value       = aws_network_interface.firewall_b_management_eni.id
}

output "firewall_b_management_eni_private_ip_address" {
  description = "Firewall B management ENI primary private IP."
  value       = aws_network_interface.firewall_b_management_eni.private_ip
}

output "firewall_vpc_transit_gateway_attachment_id" {
  description = "TGW VPC attachment id (null when attach_tgw = false; CFN returned \"no-value\")."
  value       = one(aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment[*].id)
}

output "transit_gateway_attachment_rt_a_id" {
  description = "TGW attachment subnet route table A id (not in the CFN outputs; convenience)."
  value       = aws_route_table.transit_gateway_attachment_rt_a.id
}

output "transit_gateway_attachment_rt_b_id" {
  description = "TGW attachment subnet route table B id (not in the CFN outputs; convenience)."
  value       = aws_route_table.transit_gateway_attachment_rt_b.id
}
