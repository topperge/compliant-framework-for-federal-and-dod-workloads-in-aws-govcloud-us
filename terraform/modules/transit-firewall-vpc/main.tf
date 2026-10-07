# Source: source/repositories/compliant-framework-transit-core/templates/transit-firewall-vpc.yml
# (plus /compliant/framework/transit/firewall-vpc/tgw-attach/id from transit-init.yml)

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  has_vpc_nipr_cidr  = var.vpc_nipr_cidr != "0.0.0.0/0"
  add_nat_tgw_route  = var.enable_igw && var.attach_tgw
  rfc1918_cidrs      = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  azs                = data.aws_availability_zones.available.names
  flow_log_prefix    = "${var.name}-vpc-flow-logs-"
  external_rt_ids    = { a = aws_route_table.external_rt_a.id, b = aws_route_table.external_rt_b.id }
  external_tgw_route = { for p in setproduct(keys(local.external_rt_ids), local.rfc1918_cidrs) : "${p[0]}-${p[1]}" => { rt = p[0], cidr = p[1] } }
}

#
# VPC
#
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = var.instance_tenancy

  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

resource "aws_vpc_ipv4_cidr_block_association" "vpc_nipr_cidr" {
  count      = local.has_vpc_nipr_cidr ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.vpc_nipr_cidr
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name              = var.flow_log_group_name
  name_prefix       = var.flow_log_group_name == null ? local.flow_log_prefix : null
  retention_in_days = 365
  tags              = var.tags
}

resource "aws_iam_role" "vpc_flow_log_cloudwatch_role" {
  name        = var.flow_log_role_name
  name_prefix = var.flow_log_role_name == null ? substr(local.flow_log_prefix, 0, 38) : null
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["vpc-flow-logs.amazonaws.com"] }
      Action    = ["sts:AssumeRole"]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_log_cloudwatch_role_root" {
  name = "root"
  role = aws_iam_role.vpc_flow_log_cloudwatch_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Resource = aws_cloudwatch_log_group.vpc_flow_log_group.arn
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
      ]
    }]
  })
}

resource "aws_flow_log" "vpc_flow_log_cloudwatch" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_cloudwatch_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  vpc_id          = aws_vpc.vpc.id
  traffic_type    = "ALL"
  tags            = var.tags
}

resource "aws_flow_log" "vpc_flow_log_s3" {
  log_destination_type = "s3"
  log_destination      = var.logging_bucket_arn
  vpc_id               = aws_vpc.vpc.id
  traffic_type         = "ALL"
  tags                 = var.tags
}

#
# SUBNETS
#
resource "aws_subnet" "external_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.external_subnet_a_cidr
  availability_zone = local.azs[0]
  tags              = merge(var.tags, { Name = "${var.name}-external-subnet-a" })
}

resource "aws_subnet" "external_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.external_subnet_b_cidr
  availability_zone = local.azs[1]
  tags              = merge(var.tags, { Name = "${var.name}-external-subnet-b" })
}

resource "aws_subnet" "internal_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.internal_subnet_a_cidr
  availability_zone = local.azs[0]
  tags              = merge(var.tags, { Name = "${var.name}-internal-subnet-a" })
}

resource "aws_subnet" "internal_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.internal_subnet_b_cidr
  availability_zone = local.azs[1]
  tags              = merge(var.tags, { Name = "${var.name}-internal-subnet-b" })
}

resource "aws_subnet" "management_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.management_subnet_a_cidr
  availability_zone = local.azs[0]
  tags              = merge(var.tags, { Name = "${var.name}-management-subnet-a" })
}

resource "aws_subnet" "management_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.management_subnet_b_cidr
  availability_zone = local.azs[1]
  tags              = merge(var.tags, { Name = "${var.name}-management-subnet-b" })
}

resource "aws_subnet" "transit_gateway_attachment_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.transit_gateway_attachment_subnet_a_cidr
  availability_zone = local.azs[0]
  tags              = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-a" })
}

resource "aws_subnet" "transit_gateway_attachment_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.transit_gateway_attachment_subnet_b_cidr
  availability_zone = local.azs[1]
  tags              = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-b" })
}

#
# INTERNET GATEWAY
#
resource "aws_internet_gateway" "igw" {
  count = var.enable_igw ? 1 : 0
  tags  = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_internet_gateway_attachment" "attach_igw" {
  count               = var.enable_igw ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  internet_gateway_id = aws_internet_gateway.igw[0].id
}

#
# TRANSIT GATEWAY ATTACHMENT / ROUTING
#
resource "aws_ec2_transit_gateway_vpc_attachment" "transit_gateway_attachment" {
  count = var.attach_tgw ? 1 : 0

  subnet_ids = [
    aws_subnet.transit_gateway_attachment_subnet_a.id,
    aws_subnet.transit_gateway_attachment_subnet_b.id,
  ]
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.vpc.id

  # The TGW has default association/propagation disabled; associations are managed by the route-table module.
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, { Name = "${var.name}-tgw-attachment" })
}

# Send RFC1918 to TGW [App A] / [App B]
resource "aws_route" "external_rt_tgw_route_rfc1918" {
  for_each = var.attach_tgw ? local.external_tgw_route : {}

  route_table_id         = local.external_rt_ids[each.value.rt]
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

#
# ROUTE TABLES
#
resource "aws_route_table" "external_rt_a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-external-rt-a" })
}

resource "aws_route_table" "external_rt_b" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-external-rt-b" })
}

resource "aws_route" "external_rt_a_igw_route" {
  count                  = var.enable_igw ? 1 : 0
  route_table_id         = aws_route_table.external_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
  depends_on             = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_route" "external_rt_b_igw_route" {
  count                  = var.enable_igw ? 1 : 0
  route_table_id         = aws_route_table.external_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
  depends_on             = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_route_table_association" "external_subnet_rt_association_a" {
  subnet_id      = aws_subnet.external_subnet_a.id
  route_table_id = aws_route_table.external_rt_a.id
}

resource "aws_route_table_association" "external_subnet_rt_association_b" {
  subnet_id      = aws_subnet.external_subnet_b.id
  route_table_id = aws_route_table.external_rt_b.id
}

resource "aws_route_table" "internal_rt" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-internal-rt" })
}

resource "aws_route_table_association" "internal_subnet_rt_association_a" {
  subnet_id      = aws_subnet.internal_subnet_a.id
  route_table_id = aws_route_table.internal_rt.id
}

resource "aws_route_table_association" "internal_subnet_rt_association_b" {
  subnet_id      = aws_subnet.internal_subnet_b.id
  route_table_id = aws_route_table.internal_rt.id
}

resource "aws_route_table" "management_rt" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-management-rt" })
}

resource "aws_route" "management_rt_igw_route" {
  count                  = var.enable_igw ? 1 : 0
  route_table_id         = aws_route_table.management_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
  depends_on             = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_route_table_association" "management_subnet_rt_association_a" {
  subnet_id      = aws_subnet.management_subnet_a.id
  route_table_id = aws_route_table.management_rt.id
}

resource "aws_route_table_association" "management_subnet_rt_association_b" {
  subnet_id      = aws_subnet.management_subnet_b.id
  route_table_id = aws_route_table.management_rt.id
}

resource "aws_route_table" "transit_gateway_attachment_rt_a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-rt-a" })
}

resource "aws_route_table" "transit_gateway_attachment_rt_b" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-rt-b" })
}

resource "aws_route_table_association" "transit_gateway_attachment_subnet_rt_association_a" {
  subnet_id      = aws_subnet.transit_gateway_attachment_subnet_a.id
  route_table_id = aws_route_table.transit_gateway_attachment_rt_a.id
}

resource "aws_route_table_association" "transit_gateway_attachment_subnet_rt_association_b" {
  subnet_id      = aws_subnet.transit_gateway_attachment_subnet_b.id
  route_table_id = aws_route_table.transit_gateway_attachment_rt_b.id
}

#
# NAT GATEWAYS
#
resource "aws_eip" "nat_gateway_eip_a" {
  count      = var.enable_igw ? 1 : 0
  domain     = "vpc"
  tags       = merge(var.tags, { Name = "${var.name}-nat-gateway-eni-a" })
  depends_on = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_nat_gateway" "nat_gateway_a" {
  count         = var.enable_igw ? 1 : 0
  allocation_id = aws_eip.nat_gateway_eip_a[0].allocation_id
  subnet_id     = aws_subnet.external_subnet_a.id
  tags          = merge(var.tags, { Name = "${var.name}-nat-gateway-a" })
}

resource "aws_route" "transit_gateway_attachment_rt_a_nat_gateway_route" {
  count                  = local.add_nat_tgw_route ? 1 : 0
  route_table_id         = aws_route_table.transit_gateway_attachment_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_a[0].id
}

resource "aws_eip" "nat_gateway_eip_b" {
  count      = var.enable_igw ? 1 : 0
  domain     = "vpc"
  tags       = merge(var.tags, { Name = "${var.name}-nat-gateway-eni-b" })
  depends_on = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_nat_gateway" "nat_gateway_b" {
  count         = var.enable_igw ? 1 : 0
  allocation_id = aws_eip.nat_gateway_eip_b[0].allocation_id
  subnet_id     = aws_subnet.external_subnet_b.id
  tags          = merge(var.tags, { Name = "${var.name}-nat-gateway-b" })
}

resource "aws_route" "transit_gateway_attachment_rt_b_nat_gateway_route" {
  count                  = local.add_nat_tgw_route ? 1 : 0
  route_table_id         = aws_route_table.transit_gateway_attachment_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_b[0].id
}

#
# FIREWALL NETWORK INTERFACES
#
resource "aws_network_interface" "firewall_a_external_eni" {
  subnet_id = aws_subnet.external_subnet_a.id
  tags      = var.tags
}

resource "aws_network_interface" "firewall_b_external_eni" {
  subnet_id = aws_subnet.external_subnet_b.id
  tags      = var.tags
}

resource "aws_network_interface" "firewall_a_internal_eni" {
  subnet_id         = aws_subnet.internal_subnet_a.id
  source_dest_check = false
  tags              = var.tags
}

resource "aws_eip" "firewall_a_internal_eip" {
  domain = "vpc"
  tags   = var.tags
}

resource "aws_eip_association" "firewall_a_internal_eip_association" {
  allocation_id        = aws_eip.firewall_a_internal_eip.allocation_id
  network_interface_id = aws_network_interface.firewall_a_internal_eni.id
}

resource "aws_network_interface" "firewall_b_internal_eni" {
  subnet_id         = aws_subnet.internal_subnet_b.id
  source_dest_check = false
  tags              = var.tags
}

resource "aws_eip" "firewall_b_internal_eip" {
  domain = "vpc"
  tags   = var.tags
}

resource "aws_eip_association" "firewall_b_internal_eip_association" {
  allocation_id        = aws_eip.firewall_b_internal_eip.allocation_id
  network_interface_id = aws_network_interface.firewall_b_internal_eni.id
}

resource "aws_network_interface" "firewall_a_management_eni" {
  subnet_id = aws_subnet.management_subnet_a.id
  tags      = var.tags
}

resource "aws_network_interface" "firewall_b_management_eni" {
  subnet_id = aws_subnet.management_subnet_b.id
  tags      = var.tags
}

#
# Store values into SSM Parameter Store (from transit-init.yml)
#
resource "aws_ssm_parameter" "firewall_vpc_transit_gateway_attachment_id" {
  name  = "/compliant/framework/transit/firewall-vpc/tgw-attach/id"
  type  = "String"
  value = try(aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment[0].id, "no-value")
  tags  = var.tags
}
