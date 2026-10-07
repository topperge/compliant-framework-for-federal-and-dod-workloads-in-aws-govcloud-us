# Source: source/repositories/compliant-framework-transit-core/templates/transit-attach-tenant.yml
#
# Associates a tenant VPC's transit gateway attachment with the internal route
# table and propagates its routes into the shared route tables. Must run with a
# provider for the TRANSIT account (the transit gateway owner).

resource "aws_ec2_transit_gateway_route_table_association" "tenant_vpc_association" {
  transit_gateway_attachment_id  = var.tgw_attachment_id
  transit_gateway_route_table_id = var.internal_route_table_id

  lifecycle {
    precondition {
      condition     = !var.enable_directory_vpc || var.directory_route_table_id != null
      error_message = "enable_directory_vpc requires directory_route_table_id."
    }
    precondition {
      condition     = !var.enable_virtual_firewall || var.firewall_route_table_id != null
      error_message = "enable_virtual_firewall requires firewall_route_table_id."
    }
    precondition {
      condition     = !var.enable_vpc_firewall || var.inspection_route_table_id != null
      error_message = "enable_vpc_firewall requires inspection_route_table_id."
    }
    precondition {
      condition     = !var.enable_external_access_vpc || var.external_access_route_table_id != null
      error_message = "enable_external_access_vpc requires external_access_route_table_id."
    }
  }
}

# CFN logical id: rTenantVpcPropagationTopManagementServicesRt (sic)
resource "aws_ec2_transit_gateway_route_table_propagation" "tenant_vpc_propagation_to_management_services_rt" {
  transit_gateway_attachment_id  = var.tgw_attachment_id
  transit_gateway_route_table_id = var.management_services_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tenant_vpc_propagation_to_inspection_rt" {
  count = var.enable_vpc_firewall ? 1 : 0

  transit_gateway_attachment_id  = var.tgw_attachment_id
  transit_gateway_route_table_id = var.inspection_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tenant_vpc_propagation_to_firewall_rt" {
  count = var.enable_virtual_firewall ? 1 : 0

  transit_gateway_attachment_id  = var.tgw_attachment_id
  transit_gateway_route_table_id = var.firewall_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tenant_vpc_propagation_to_directory_rt" {
  count = var.enable_directory_vpc ? 1 : 0

  transit_gateway_attachment_id  = var.tgw_attachment_id
  transit_gateway_route_table_id = var.directory_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tenant_vpc_propagation_to_external_access_rt" {
  count = var.enable_external_access_vpc ? 1 : 0

  transit_gateway_attachment_id  = var.tgw_attachment_id
  transit_gateway_route_table_id = var.external_access_route_table_id
}
