output "vpc_id" {
  description = "DMZ VPC id."
  value       = aws_vpc.vpc.id
}

output "public_subnet_a_id" {
  description = "Public subnet A id (shared with the organization via RAM)."
  value       = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  description = "Public subnet B id (shared with the organization via RAM)."
  value       = aws_subnet.public_subnet_b.id
}

output "public_rt_id" {
  description = "Public subnet route table id."
  value       = aws_route_table.public_rt.id
}

output "transit_gateway_attachment_rt_id" {
  description = "TGW attachment subnet route table id."
  value       = aws_route_table.transit_gateway_attachment_rt.id
}

output "transit_gateway_attachment_id" {
  description = "TGW VPC attachment id."
  value       = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
}
