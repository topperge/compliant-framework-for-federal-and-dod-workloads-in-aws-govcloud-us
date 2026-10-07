output "transit_gateway_id" {
  description = "Transit Gateway id (shared with the organization through RAM)."
  value       = module.transit_gateway.transit_gateway_id
}

output "transit_gateway_route_table_ids" {
  description = "Transit Gateway route table ids (null when the feature is disabled)."
  value = {
    internal            = module.transit_gateway.transit_gateway_internal_route_table_id
    management_services = module.transit_gateway.transit_gateway_management_services_route_table_id
    directory           = module.transit_gateway.transit_gateway_directory_route_table_id
    external_access     = module.transit_gateway.transit_gateway_external_access_route_table_id
    firewall            = module.transit_gateway.transit_gateway_firewall_route_table_id
    dmz                 = module.transit_gateway.transit_gateway_dmz_route_table_id
    inspection          = module.transit_gateway.transit_gateway_inspection_route_table_id
  }
}

output "management_services_vpc_id" {
  description = "Management Services VPC id."
  value       = module.management_services_vpc.vpc_id
}

output "directory_vpc_id" {
  description = "Directory VPC id (null when disabled)."
  value       = one(module.directory_vpc[*].vpc_id)
}

output "external_access_vpc_id" {
  description = "External Access VPC id (null when disabled)."
  value       = one(module.external_access_vpc[*].vpc_id)
}

output "firewall_vpc_id" {
  description = "Virtual firewall VPC id (null when disabled)."
  value       = one(module.firewall_vpc[*].vpc_id)
}

output "service_catalog_portfolio_id" {
  description = "Tenant Services Service Catalog portfolio id."
  value       = module.service_catalog_portfolio.portfolio_id
}
