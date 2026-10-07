# The CFN template declares no Outputs; these are convenience outputs.

output "route_table_association_id" {
  description = "Id of the tenant attachment's association with the internal route table."
  value       = aws_ec2_transit_gateway_route_table_association.tenant_vpc_association.id
}

output "propagated_route_table_ids" {
  description = "TGW route table ids the tenant attachment is propagated into."
  value = concat(
    [aws_ec2_transit_gateway_route_table_propagation.tenant_vpc_propagation_to_management_services_rt.transit_gateway_route_table_id],
    aws_ec2_transit_gateway_route_table_propagation.tenant_vpc_propagation_to_inspection_rt[*].transit_gateway_route_table_id,
    aws_ec2_transit_gateway_route_table_propagation.tenant_vpc_propagation_to_firewall_rt[*].transit_gateway_route_table_id,
    aws_ec2_transit_gateway_route_table_propagation.tenant_vpc_propagation_to_directory_rt[*].transit_gateway_route_table_id,
    aws_ec2_transit_gateway_route_table_propagation.tenant_vpc_propagation_to_external_access_rt[*].transit_gateway_route_table_id,
  )
}
