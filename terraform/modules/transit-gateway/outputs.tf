output "transit_gateway_id" {
  description = "Transit gateway id."
  value       = aws_ec2_transit_gateway.transit_gateway.id
}

output "transit_gateway_arn" {
  description = "Transit gateway ARN (not in the CFN outputs; convenience)."
  value       = aws_ec2_transit_gateway.transit_gateway.arn
}

output "transit_gateway_internal_route_table_id" {
  description = "Internal (tenant workloads) TGW route table id."
  value       = aws_ec2_transit_gateway_route_table.internal.id
}

output "transit_gateway_management_services_route_table_id" {
  description = "Management services TGW route table id."
  value       = aws_ec2_transit_gateway_route_table.management_services.id
}

output "transit_gateway_directory_route_table_id" {
  description = "Directory TGW route table id (null unless enable_directory_vpc)."
  value       = one(aws_ec2_transit_gateway_route_table.directory[*].id)
}

output "transit_gateway_external_access_route_table_id" {
  description = "External access TGW route table id (null unless enable_external_access_vpc)."
  value       = one(aws_ec2_transit_gateway_route_table.external_access[*].id)
}

output "transit_gateway_firewall_route_table_id" {
  description = "Virtual firewall TGW route table id (null unless enable_virtual_firewall)."
  value       = one(aws_ec2_transit_gateway_route_table.firewall[*].id)
}

output "transit_gateway_dmz_route_table_id" {
  description = "DMZ TGW route table id (null unless enable_vpc_firewall)."
  value       = one(aws_ec2_transit_gateway_route_table.dmz[*].id)
}

output "transit_gateway_inspection_route_table_id" {
  description = "Inspection TGW route table id (null unless enable_vpc_firewall)."
  value       = one(aws_ec2_transit_gateway_route_table.inspection[*].id)
}

output "resource_share_arn" {
  description = "ARN of the transit-gateway-share RAM resource share (not in the CFN outputs; convenience)."
  value       = aws_ram_resource_share.resource_share.arn
}
