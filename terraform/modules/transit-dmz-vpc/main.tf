# Source: source/repositories/compliant-framework-transit-core/templates/transit-dmz-vpc.yml

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  rfc1918_cidrs   = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  azs             = data.aws_availability_zones.available.names
  flow_log_prefix = "${var.name}-vpc-flow-logs-"
  subnet_arn_base = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:subnet"
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
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = local.azs[0]
  tags              = merge(var.tags, { Name = "${var.name}-public-subnet-a" })
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = local.azs[1]
  tags              = merge(var.tags, { Name = "${var.name}-public-subnet-b" })
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
  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_internet_gateway_attachment" "attach_igw" {
  vpc_id              = aws_vpc.vpc.id
  internet_gateway_id = aws_internet_gateway.igw.id
}

#
# TGW Attachment
#
resource "aws_ec2_transit_gateway_vpc_attachment" "transit_gateway_attachment" {
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

#
# ROUTE TABLES
#
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-public-subnet-rt" })
}

resource "aws_route_table_association" "public_rt_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Default Route to IGW
resource "aws_route" "public_rt_a_igw_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_internet_gateway_attachment.attach_igw]
}

# RFC1918 to TGW
resource "aws_route" "public_rt_a_tgw_route_rfc1918" {
  for_each = toset(local.rfc1918_cidrs)

  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = each.value
  transit_gateway_id     = var.transit_gateway_id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

resource "aws_route_table" "transit_gateway_attachment_rt" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-rt" })
}

resource "aws_route_table_association" "transit_gateway_attachment_rt_association_a" {
  subnet_id      = aws_subnet.transit_gateway_attachment_subnet_a.id
  route_table_id = aws_route_table.transit_gateway_attachment_rt.id
}

resource "aws_route_table_association" "transit_gateway_attachment_rt_association_b" {
  subnet_id      = aws_subnet.transit_gateway_attachment_subnet_b.id
  route_table_id = aws_route_table.transit_gateway_attachment_rt.id
}

#
# Share DMZ Public Subnets with Organization
#
resource "aws_ram_resource_share" "resource_share" {
  name                      = "${var.name}-public-subnet-share"
  allow_external_principals = false
  tags                      = var.tags
}

resource "aws_ram_resource_association" "public_subnet" {
  for_each = {
    a = aws_subnet.public_subnet_a.id
    b = aws_subnet.public_subnet_b.id
  }

  resource_share_arn = aws_ram_resource_share.resource_share.arn
  resource_arn       = "${local.subnet_arn_base}/${each.value}"
}

resource "aws_ram_principal_association" "organization" {
  resource_share_arn = aws_ram_resource_share.resource_share.arn
  principal          = "arn:${data.aws_partition.current.partition}:organizations::${var.central_account_id}:organization/${var.principal_org_id}"
}

#
# Store values into SSM Parameter Store
#
resource "aws_ssm_parameter" "dmz_vpc_transit_gateway_attachment_id" {
  name  = "/compliant/framework/transit/dmz-vpc/tgw-attach/id"
  type  = "String"
  value = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
  tags  = var.tags
}
