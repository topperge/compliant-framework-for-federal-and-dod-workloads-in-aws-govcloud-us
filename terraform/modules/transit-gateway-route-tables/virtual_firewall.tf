# virtual-firewall/*.yml : resources specific to the virtual-firewall flavour
# (firewall VPC with VPN-attached virtual firewall appliances).
#
# The commented-out VPN default routes / VPN associations in the source templates
# ("Causes 'Internal Failure'") were never deployed and are not translated.

################################################################################
# Default routes to the firewall VPC (internal / management services / directory)
# and firewall VPC propagation into external access
################################################################################

resource "aws_ec2_transit_gateway_route" "internal_rt_default_route_firewall_vpc" {
  count = local.use_virtual_firewall_family && local.attach_fw_vpc ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.firewall_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.internal_route_table_id
}

resource "aws_ec2_transit_gateway_route" "management_services_rt_default_route_firewall_vpc" {
  count = local.use_virtual_firewall_family && local.attach_fw_vpc ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.firewall_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.management_services_route_table_id
}

resource "aws_ec2_transit_gateway_route" "directory_rt_default_route_firewall_vpc" {
  count = local.use_virtual_firewall_family && local.directory && local.attach_fw_vpc ? 1 : 0

  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = var.firewall_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.directory_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "external_access_rt_propagation_firewall_vpc" {
  count = local.use_virtual_firewall_family && local.external && local.attach_fw_vpc ? 1 : 0

  transit_gateway_attachment_id  = var.firewall_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.external_access_route_table_id
}

################################################################################
# Firewall Route Table (rFirewallRtStack, condition cEnableVirtualFirewall)
################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "firewall_rt_association_firewall_vpc" {
  count = local.firewall_rt && local.attach_fw_vpc ? 1 : 0

  transit_gateway_attachment_id  = var.firewall_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.firewall_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "firewall_rt_propagation_management_services_vpc" {
  count = local.firewall_rt ? 1 : 0

  transit_gateway_attachment_id  = var.management_services_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.firewall_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "firewall_rt_propagation_external_access_vpc" {
  count = local.firewall_rt && local.external ? 1 : 0

  transit_gateway_attachment_id  = var.external_access_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.firewall_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "firewall_rt_propagation_directory_vpc" {
  count = local.firewall_rt && local.directory ? 1 : 0

  transit_gateway_attachment_id  = var.directory_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.firewall_route_table_id
}
