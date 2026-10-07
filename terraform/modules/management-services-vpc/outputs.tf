output "vpc_id" {
  description = "VPC ID (oVpcId)."
  value       = aws_vpc.vpc.id
}

output "application_subnet_a_id" {
  description = "Application subnet A ID (oApplicationSubnetAId)."
  value       = aws_subnet.application_a.id
}

output "application_subnet_b_id" {
  description = "Application subnet B ID (oApplicationSubnetBId)."
  value       = aws_subnet.application_b.id
}

output "application_rt_a" {
  description = "Application route table A ID (oApplicationRtA)."
  value       = aws_route_table.application_a.id
}

output "application_rt_b" {
  description = "Application route table B ID (oApplicationRtB)."
  value       = aws_route_table.application_b.id
}

output "data_subnet_a_id" {
  description = "Data subnet A ID (oDataSubnetAId)."
  value       = aws_subnet.data_a.id
}

output "data_subnet_b_id" {
  description = "Data subnet B ID (oDataSubnetBId)."
  value       = aws_subnet.data_b.id
}

output "data_rt_a" {
  description = "Data route table A ID (oDataRtA)."
  value       = aws_route_table.data_a.id
}

output "data_rt_b" {
  description = "Data route table B ID (oDataRtB)."
  value       = aws_route_table.data_b.id
}

output "transit_gateway_attachment_subnet_a_id" {
  description = "Transit gateway attachment subnet A ID (oTransitGatewayAttachmentSubnetAId)."
  value       = aws_subnet.transit_gateway_attachment_a.id
}

output "transit_gateway_attachment_subnet_b_id" {
  description = "Transit gateway attachment subnet B ID (oTransitGatewayAttachmentSubnetBId)."
  value       = aws_subnet.transit_gateway_attachment_b.id
}

output "transit_gateway_attachment_rt_id" {
  description = "Transit gateway attachment route table ID (oTransitGatewayAttachmentRtId)."
  value       = aws_route_table.transit_gateway_attachment.id
}

output "transit_gateway_attachment_id" {
  description = "Transit gateway VPC attachment ID (oTransitGatewayAttachmentId)."
  value       = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
}
