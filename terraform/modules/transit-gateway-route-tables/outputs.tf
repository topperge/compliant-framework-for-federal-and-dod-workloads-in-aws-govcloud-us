# The CFN templates declare no Outputs. The values below are convenience outputs
# so callers can order dependent work (e.g. tenant attachments) after routing.

output "firewall_family" {
  description = "Which template family was applied to the internal/management-services/directory/external-access route tables: \"vpc-firewall\" or \"virtual-firewall\"."
  value       = local.use_vpc_firewall_family ? "vpc-firewall" : "virtual-firewall"
}

output "route_table_association_ids" {
  description = "Map of route table association resource ids created by this module (null when disabled)."
  value = {
    management_services_vpc = aws_ec2_transit_gateway_route_table_association.management_services_rt_association_management_vpc.id
    directory_vpc           = one(aws_ec2_transit_gateway_route_table_association.directory_rt_association_directory_vpc[*].id)
    external_access_vpc     = one(aws_ec2_transit_gateway_route_table_association.external_access_rt_association_external_access_vpc[*].id)
    firewall_vpc            = one(aws_ec2_transit_gateway_route_table_association.firewall_rt_association_firewall_vpc[*].id)
    dmz_vpc                 = one(aws_ec2_transit_gateway_route_table_association.dmz_rt_association_dmz_vpc[*].id)
    inspection_vpc          = one(aws_ec2_transit_gateway_route_table_association.inspection_rt_association_inspection_vpc[*].id)
  }
}
