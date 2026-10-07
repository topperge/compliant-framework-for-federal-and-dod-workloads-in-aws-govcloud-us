# Source: source/repositories/compliant-framework-transit-core/templates/transit-gateway.yml
# (plus the enable-flag SSM parameters from transit-init.yml)

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

#
# Transit Gateway
#
resource "aws_ec2_transit_gateway" "transit_gateway" {
  amazon_side_asn                 = var.transit_gateway_amazon_side_asn
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = merge(var.tags, { Name = "transit-gateway" })
}

# Tenant workloads (non core applications)
resource "aws_ec2_transit_gateway_route_table" "internal" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  tags               = merge(var.tags, { Name = "internal-tgw-rt" })
}

resource "aws_ec2_transit_gateway_route_table" "management_services" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  tags               = merge(var.tags, { Name = "management-services-tgw-rt" })
}

# Directory Services (AD and DNS)
resource "aws_ec2_transit_gateway_route_table" "directory" {
  count              = var.enable_directory_vpc ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  tags               = merge(var.tags, { Name = "directory-tgw-rt" })
}

# Provides OOB access to management services
resource "aws_ec2_transit_gateway_route_table" "external_access" {
  count              = var.enable_external_access_vpc ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  tags               = merge(var.tags, { Name = "external-access-tgw-rt" })
}

# Virtual Firewall
resource "aws_ec2_transit_gateway_route_table" "firewall" {
  count              = var.enable_virtual_firewall ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  tags               = merge(var.tags, { Name = "firewall-tgw-rt" })
}

# VPC Firewall
resource "aws_ec2_transit_gateway_route_table" "dmz" {
  count              = var.enable_vpc_firewall ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  tags               = merge(var.tags, { Name = "dmz-tgw-rt" })
}

resource "aws_ec2_transit_gateway_route_table" "inspection" {
  count              = var.enable_vpc_firewall ? 1 : 0
  transit_gateway_id = aws_ec2_transit_gateway.transit_gateway.id
  tags               = merge(var.tags, { Name = "inspection-tgw-rt" })
}

#
# Share Transit Gateway with Organization
#
resource "aws_ram_resource_share" "resource_share" {
  name                      = "transit-gateway-share"
  allow_external_principals = false
  tags                      = var.tags
}

resource "aws_ram_resource_association" "transit_gateway" {
  resource_share_arn = aws_ram_resource_share.resource_share.arn
  resource_arn       = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:transit-gateway/${aws_ec2_transit_gateway.transit_gateway.id}"
}

resource "aws_ram_principal_association" "organization" {
  resource_share_arn = aws_ram_resource_share.resource_share.arn
  principal          = "arn:${data.aws_partition.current.partition}:organizations::${var.central_account_id}:organization/${var.principal_org_id}"
}
