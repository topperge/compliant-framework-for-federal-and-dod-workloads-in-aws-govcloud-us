# Source: source/repositories/compliant-framework-transit-core/templates/transit-inspection-vpc.yml

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  rfc1918_cidrs   = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  azs             = data.aws_availability_zones.available.names
  flow_log_prefix = "${var.name}-vpc-flow-logs-"
  firewall_rt_ids = { a = aws_route_table.firewall_rt_a.id, b = aws_route_table.firewall_rt_b.id }
  firewall_tgw_route = {
    for p in setproduct(keys(local.firewall_rt_ids), local.rfc1918_cidrs) : "${p[0]}-${p[1]}" => { rt = p[0], cidr = p[1] }
  }
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

resource "aws_subnet" "firewall_subnet_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.firewall_subnet_a_cidr
  availability_zone = local.azs[0]
  tags              = merge(var.tags, { Name = "${var.name}-firewall-subnet-a" })
}

resource "aws_subnet" "firewall_subnet_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.firewall_subnet_b_cidr
  availability_zone = local.azs[1]
  tags              = merge(var.tags, { Name = "${var.name}-firewall-subnet-b" })
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
# NAT GATEWAYS
#
resource "aws_eip" "nat_gateway_a_eip" {
  domain     = "vpc"
  tags       = merge(var.tags, { Name = "${var.name}-nat-gateway-eni-a" })
  depends_on = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_nat_gateway" "nat_gateway_a" {
  allocation_id = aws_eip.nat_gateway_a_eip.allocation_id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags          = merge(var.tags, { Name = "${var.name}-nat-gateway-a" })
}

resource "aws_eip" "nat_gateway_b_eip" {
  domain     = "vpc"
  tags       = merge(var.tags, { Name = "${var.name}-nat-gateway-eni-b" })
  depends_on = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_nat_gateway" "nat_gateway_b" {
  allocation_id = aws_eip.nat_gateway_b_eip.allocation_id
  subnet_id     = aws_subnet.public_subnet_b.id
  tags          = merge(var.tags, { Name = "${var.name}-nat-gateway-b" })
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

# Public Route Table A
resource "aws_route_table" "public_rt_a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-public-subnet-rt-a" })
}

resource "aws_route_table_association" "public_subnet_a_rt_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt_a.id
}

resource "aws_route" "public_rt_a_igw_route" {
  route_table_id         = aws_route_table.public_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_internet_gateway_attachment.attach_igw]
}

# Public Route Table B
resource "aws_route_table" "public_rt_b" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-public-subnet-rt-b" })
}

resource "aws_route_table_association" "public_subnet_b_rt_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt_b.id
}

resource "aws_route" "public_rt_b_igw_route" {
  route_table_id         = aws_route_table.public_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_internet_gateway_attachment.attach_igw]
}

# Firewall Route Table A
resource "aws_route_table" "firewall_rt_a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-firewall-subnet-rt-a" })
}

resource "aws_route_table_association" "firewall_subnet_rt_a_association" {
  subnet_id      = aws_subnet.firewall_subnet_a.id
  route_table_id = aws_route_table.firewall_rt_a.id
}

resource "aws_route" "firewall_rt_a_nat_gateway_a_route" {
  route_table_id         = aws_route_table.firewall_rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_a.id
}

# Firewall Route Table B
resource "aws_route_table" "firewall_rt_b" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-firewall-subnet-rt-b" })
}

resource "aws_route_table_association" "firewall_subnet_rt_b_association" {
  subnet_id      = aws_subnet.firewall_subnet_b.id
  route_table_id = aws_route_table.firewall_rt_b.id
}

resource "aws_route" "firewall_rt_b_nat_gateway_b_route" {
  route_table_id         = aws_route_table.firewall_rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_b.id
}

# RFC1918 to TGW (firewall route tables A and B)
resource "aws_route" "firewall_rt_tgw_route_rfc1918" {
  for_each = local.firewall_tgw_route

  route_table_id         = local.firewall_rt_ids[each.value.rt]
  destination_cidr_block = each.value.cidr
  transit_gateway_id     = var.transit_gateway_id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

# TGW Attach Route Table A
resource "aws_route_table" "transit_gateway_attachment_rt_a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-rt-a" })
}

resource "aws_route_table_association" "transit_gateway_attachment_rt_a_association" {
  subnet_id      = aws_subnet.transit_gateway_attachment_subnet_a.id
  route_table_id = aws_route_table.transit_gateway_attachment_rt_a.id
}

# TGW Attach Route Table B
resource "aws_route_table" "transit_gateway_attachment_rt_b" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-rt-b" })
}

resource "aws_route_table_association" "transit_gateway_attachment_rt_b_association" {
  subnet_id      = aws_subnet.transit_gateway_attachment_subnet_b.id
  route_table_id = aws_route_table.transit_gateway_attachment_rt_b.id
}

#
# Firewall security group (public facing). Intentionally open: the firewall appliance enforces policy
# (cfn_nag W2/W5/W9/W27/W29/W42 were suppressed in the source template).
#
resource "aws_security_group" "firewall_security_group" {
  vpc_id      = aws_vpc.vpc.id
  description = "VPC Firewall Security group (Public Facing)"
  tags        = var.tags

  ingress {
    description = "Allow all traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All TCP"
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All UDP"
    protocol    = "udp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All ICMP"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# Store values into SSM Parameter Store
#
resource "aws_ssm_parameter" "inspection_vpc_transit_gateway_attachment_id" {
  name  = "/compliant/framework/transit/inspection-vpc/tgw-attach/id"
  type  = "String"
  value = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id
  tags  = var.tags
}
