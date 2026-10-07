#
# Store values into SSM Parameter Store (transit-gateway.yml)
#
locals {
  # CFN wrote the literal "xxxxxx" for route tables that are disabled.
  ssm_route_table_ids = {
    "internal-route-table"            = aws_ec2_transit_gateway_route_table.internal.id
    "management-services-route-table" = aws_ec2_transit_gateway_route_table.management_services.id
    "directory-route-table"           = try(aws_ec2_transit_gateway_route_table.directory[0].id, "xxxxxx")
    "external-access-route-table"     = try(aws_ec2_transit_gateway_route_table.external_access[0].id, "xxxxxx")
    "firewall-route-table"            = try(aws_ec2_transit_gateway_route_table.firewall[0].id, "xxxxxx")
    "dmz-route-table"                 = try(aws_ec2_transit_gateway_route_table.dmz[0].id, "xxxxxx")
    "inspection-route-table"          = try(aws_ec2_transit_gateway_route_table.inspection[0].id, "xxxxxx")
  }

  # Written by transit-init.yml (the nested-stack wrapper). Values are the strings "true"/"false".
  ssm_enabled_flags = {
    "directory-vpc"       = var.enable_directory_vpc
    "external-access-vpc" = var.enable_external_access_vpc
    "vpc-firewall"        = var.enable_vpc_firewall
    "virtual-firewall"    = var.enable_virtual_firewall
  }
}

resource "aws_ssm_parameter" "transit_gateway_id" {
  name  = "/compliant/framework/transit/transit-gateway/id"
  type  = "String"
  value = aws_ec2_transit_gateway.transit_gateway.id
  tags  = var.tags
}

resource "aws_ssm_parameter" "route_table_id" {
  for_each = local.ssm_route_table_ids

  name  = "/compliant/framework/transit/transit-gateway/${each.key}/id"
  type  = "String"
  value = each.value
  tags  = var.tags
}

resource "aws_ssm_parameter" "enabled" {
  for_each = local.ssm_enabled_flags

  name  = "/compliant/framework/transit/${each.key}/enabled"
  type  = "String"
  value = tostring(each.value)
  tags  = var.tags
}
