# vpc-firewall/*.yml : resources specific to the VPC-firewall flavour
# (DMZ VPC + inspection VPC).

################################################################################
# Default routes to the inspection VPC (internal / management services / directory)
# and inspection VPC propagation into external access
################################################################################

resource "aws_ec2_transit_gateway_route" "internal_rt_default_route_inspection_vpc" {
  count = local.use_vpc_firewall_family ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.internal_route_table_id
}

resource "aws_ec2_transit_gateway_route" "management_services_rt_default_route_inspection_vpc" {
  count = local.use_vpc_firewall_family ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.management_services_route_table_id
}

resource "aws_ec2_transit_gateway_route" "directory_rt_default_route_inspection_vpc" {
  count = local.use_vpc_firewall_family && local.directory ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.directory_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "external_access_rt_propagation_inspection_vpc" {
  count = local.use_vpc_firewall_family && local.external ? 1 : 0

  transit_gateway_attachment_id  = var.inspection_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.external_access_route_table_id
}

################################################################################
# DMZ Route Table (rDmzRtStack, condition cEnableVpcFirewall)
################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "dmz_rt_association_dmz_vpc" {
  count = local.dmz_inspect ? 1 : 0

  transit_gateway_attachment_id  = var.dmz_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.dmz_route_table_id
}

resource "aws_ec2_transit_gateway_route" "dmz_rt_default_route_inspection_vpc" {
  count = local.dmz_inspect ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.inspection_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.dmz_route_table_id
}

################################################################################
# Inspection Route Table (rInspectionRtStack, condition cEnableVpcFirewall)
################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "inspection_rt_association_inspection_vpc" {
  count = local.dmz_inspect ? 1 : 0

  transit_gateway_attachment_id  = var.inspection_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.inspection_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_rt_propagation_dmz_vpc" {
  count = local.dmz_inspect ? 1 : 0

  transit_gateway_attachment_id  = var.dmz_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.inspection_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_rt_propagation_management_services_vpc" {
  count = local.dmz_inspect ? 1 : 0

  transit_gateway_attachment_id  = var.management_services_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.inspection_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_rt_propagation_external_access_vpc" {
  count = local.dmz_inspect && local.external ? 1 : 0

  transit_gateway_attachment_id  = var.external_access_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.inspection_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_rt_propagation_directory_vpc" {
  count = local.dmz_inspect && local.directory ? 1 : 0

  transit_gateway_attachment_id  = var.directory_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.inspection_route_table_id
}
