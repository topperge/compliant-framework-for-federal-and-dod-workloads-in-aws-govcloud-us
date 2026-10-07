output "transit_gateway_attachment_id" {
  description = "Transit gateway VPC attachment ID (oTransitGatewayAttachmentId)."
  value       = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
}

# Not an output of the source template; provided for composition.
output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.vpc.id
}
