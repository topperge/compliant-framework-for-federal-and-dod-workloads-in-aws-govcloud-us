# Source: source/repositories/compliant-framework-transit-core/templates/transit-gateway-route-tables.yml
# (plus virtual-firewall/*.yml and vpc-firewall/*.yml sub-templates)
#
# The CFN wrapper deployed one nested stack per route table and picked the
# "vpc-firewall" or "virtual-firewall" flavour of the internal, management
# services, directory and external access templates based on enable_vpc_firewall.
# Associations/propagations identical in both flavours live in this file;
# flavour-specific resources live in virtual_firewall.tf / vpc_firewall.tf.

locals {
  # Wrapper: config = cEnableVpcFirewall ? vpc-firewall : virtual-firewall
  use_vpc_firewall_family     = var.enable_vpc_firewall
  use_virtual_firewall_family = !var.enable_vpc_firewall

  directory     = var.enable_directory_vpc
  external      = var.enable_external_access_vpc
  dir_and_ext   = var.enable_directory_vpc && var.enable_external_access_vpc
  firewall_rt   = var.enable_virtual_firewall # rFirewallRtStack (always virtual-firewall template)
  dmz_inspect   = var.enable_vpc_firewall     # rDmzRtStack / rInspectionRtStack
  attach_fw_vpc = var.attach_firewall_vpc
}

# Fail early (at plan) when an enabled feature is missing its ids.
resource "terraform_data" "input_validation" {
  lifecycle {
    precondition {
      condition     = !local.directory || (var.directory_route_table_id != null && var.directory_vpc_tgw_attachment_id != null)
      error_message = "enable_directory_vpc requires directory_route_table_id and directory_vpc_tgw_attachment_id."
    }
    precondition {
      condition     = !local.external || (var.external_access_route_table_id != null && var.external_access_vpc_tgw_attachment_id != null)
      error_message = "enable_external_access_vpc requires external_access_route_table_id and external_access_vpc_tgw_attachment_id."
    }
    precondition {
      condition     = !local.firewall_rt || var.firewall_route_table_id != null
      error_message = "enable_virtual_firewall requires firewall_route_table_id."
    }
    precondition {
      condition     = !local.attach_fw_vpc || !(local.use_virtual_firewall_family || local.firewall_rt) || var.firewall_vpc_tgw_attachment_id != null
      error_message = "attach_firewall_vpc with the virtual-firewall family requires firewall_vpc_tgw_attachment_id."
    }
    precondition {
      condition     = !local.dmz_inspect || (var.dmz_route_table_id != null && var.inspection_route_table_id != null && var.dmz_vpc_tgw_attachment_id != null && var.inspection_vpc_tgw_attachment_id != null)
      error_message = "enable_vpc_firewall requires dmz_route_table_id, inspection_route_table_id, dmz_vpc_tgw_attachment_id and inspection_vpc_tgw_attachment_id."
    }
  }
}

################################################################################
# Internal Route Table (rInternalRtStack) - no associations
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "internal_rt_propagation_management_services_vpc" {
  transit_gateway_attachment_id  = var.management_services_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.internal_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "internal_rt_propagation_external_access_vpc" {
  count = local.external ? 1 : 0

  transit_gateway_attachment_id  = var.external_access_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.internal_route_table_id
}

################################################################################
# Management Services Route Table (rManagementServicesRtStack)
################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "management_services_rt_association_management_vpc" {
  transit_gateway_attachment_id  = var.management_services_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.management_services_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "management_services_rt_propagation_external_access_vpc" {
  count = local.external ? 1 : 0

  transit_gateway_attachment_id  = var.external_access_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.management_services_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "management_services_rt_propagation_directory_vpc" {
  count = local.directory ? 1 : 0

  transit_gateway_attachment_id  = var.directory_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.management_services_route_table_id
}

################################################################################
# Directory Route Table (rDirectoryRtStack, condition cEnableDirectoryVpc)
################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "directory_rt_association_directory_vpc" {
  count = local.directory ? 1 : 0

  transit_gateway_attachment_id  = var.directory_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.directory_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "directory_rt_propagation_management_services_vpc" {
  count = local.directory ? 1 : 0

  transit_gateway_attachment_id  = var.management_services_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.directory_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "directory_rt_propagation_external_access_vpc" {
  count = local.dir_and_ext ? 1 : 0

  transit_gateway_attachment_id  = var.external_access_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.directory_route_table_id
}

################################################################################
# External Access Route Table (rExternalAccessRtStack, condition cEnableExternalAccessVpc)
################################################################################

resource "aws_ec2_transit_gateway_route_table_association" "external_access_rt_association_external_access_vpc" {
  count = local.external ? 1 : 0

  transit_gateway_attachment_id  = var.external_access_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.external_access_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "external_access_rt_propagation_management_services_vpc" {
  count = local.external ? 1 : 0

  transit_gateway_attachment_id  = var.management_services_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.external_access_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "external_access_rt_propagation_directory_vpc" {
  count = local.dir_and_ext ? 1 : 0

  transit_gateway_attachment_id  = var.directory_vpc_tgw_attachment_id
  transit_gateway_route_table_id = var.external_access_route_table_id
}
