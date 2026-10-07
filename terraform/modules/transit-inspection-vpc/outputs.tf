output "vpc_id" {
  description = "Inspection VPC id."
  value       = aws_vpc.vpc.id
}

output "public_subnet_a_id" {
  description = "Public subnet A id."
  value       = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  description = "Public subnet B id."
  value       = aws_subnet.public_subnet_b.id
}

output "public_rt_a_id" {
  description = "Public route table A id."
  value       = aws_route_table.public_rt_a.id
}

output "public_rt_b_id" {
  description = "Public route table B id."
  value       = aws_route_table.public_rt_b.id
}

output "firewall_subnet_a_id" {
  description = "Firewall subnet A id."
  value       = aws_subnet.firewall_subnet_a.id
}

output "firewall_subnet_b_id" {
  description = "Firewall subnet B id."
  value       = aws_subnet.firewall_subnet_b.id
}

output "firewall_rt_a_id" {
  description = "Firewall route table A id."
  value       = aws_route_table.firewall_rt_a.id
}

output "firewall_rt_b_id" {
  description = "Firewall route table B id."
  value       = aws_route_table.firewall_rt_b.id
}

output "transit_gateway_attachment_subnet_a_id" {
  description = "TGW attachment subnet A id."
  value       = aws_subnet.transit_gateway_attachment_subnet_a.id
}

output "transit_gateway_attachment_subnet_b_id" {
  description = "TGW attachment subnet B id."
  value       = aws_subnet.transit_gateway_attachment_subnet_b.id
}

output "transit_gateway_attachment_rt_a_id" {
  description = "TGW attachment route table A id."
  value       = aws_route_table.transit_gateway_attachment_rt_a.id
}

output "transit_gateway_attachment_rt_b_id" {
  description = "TGW attachment route table B id."
  value       = aws_route_table.transit_gateway_attachment_rt_b.id
}

output "transit_gateway_attachment_id" {
  description = "TGW VPC attachment id."
  value       = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
}

output "nat_gateway_a_id" {
  description = "NAT gateway A id."
  value       = aws_nat_gateway.nat_gateway_a.id
}

output "nat_gateway_b_id" {
  description = "NAT gateway B id."
  value       = aws_nat_gateway.nat_gateway_b.id
}

output "firewall_security_group_id" {
  description = "Firewall security group id."
  value       = aws_security_group.firewall_security_group.id
}
