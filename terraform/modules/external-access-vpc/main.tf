# Source: source/repositories/compliant-framework-management-services-core/templates/management-services-external-access-vpc.yml

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  az_a = data.aws_availability_zones.available.names[0]
  az_b = data.aws_availability_zones.available.names[1]

  # Default matches management-services-init.yml: arn:<partition>:s3:::flow-logs-<account>-<region>
  logging_bucket_arn = coalesce(var.logging_bucket_arn, "arn:${local.partition}:s3:::flow-logs-${local.account_id}-${local.region}")
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

# CloudFormation generated the log group / role names; Terraform uses name_prefix.
# ignore_changes on the name lets existing (imported) resources be adopted without replacement.
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name_prefix       = "${var.name}-vpc-flow-logs-"
  retention_in_days = 365
  tags              = var.tags

  lifecycle {
    ignore_changes = [name, name_prefix]
  }
}

data "aws_iam_policy_document" "vpc_flow_log_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_flow_log_cloudwatch" {
  name_prefix        = "${var.name}-vpc-flow-logs-"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_assume.json
  tags               = var.tags

  lifecycle {
    ignore_changes = [name, name_prefix]
  }
}

resource "aws_iam_role_policy" "vpc_flow_log_cloudwatch" {
  name = "root"
  role = aws_iam_role.vpc_flow_log_cloudwatch.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      # CFN LogGroup.Arn ends in ":*"; keep the same effective resource
      Resource = "${aws_cloudwatch_log_group.vpc_flow_log.arn}:*"
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
  iam_role_arn         = aws_iam_role.vpc_flow_log_cloudwatch.arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_log.arn
  vpc_id               = aws_vpc.vpc.id
  traffic_type         = "ALL"
  tags                 = var.tags
}

resource "aws_flow_log" "vpc_flow_log_s3" {
  log_destination_type = "s3"
  log_destination      = local.logging_bucket_arn
  vpc_id               = aws_vpc.vpc.id
  traffic_type         = "ALL"
  tags                 = var.tags
}

#
# INTERNET GATEWAY
#
resource "aws_internet_gateway" "igw" {
  tags = merge(var.tags, { Name = "${var.name}-vpc-igw" })

  depends_on = [aws_vpc.vpc]
}

resource "aws_internet_gateway_attachment" "attach_igw" {
  vpc_id              = aws_vpc.vpc.id
  internet_gateway_id = aws_internet_gateway.igw.id
}

#
# SUBNETS
#
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = local.az_a
  tags              = merge(var.tags, { Name = "${var.name}-public-subnet-a" })
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = local.az_b
  tags              = merge(var.tags, { Name = "${var.name}-public-subnet-b" })
}

resource "aws_subnet" "application_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.application_subnet_a_cidr
  availability_zone = local.az_a
  tags              = merge(var.tags, { Name = "${var.name}-subnet-a" })
}

resource "aws_subnet" "application_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.application_subnet_b_cidr
  availability_zone = local.az_b
  tags              = merge(var.tags, { Name = "${var.name}-subnet-b" })
}

resource "aws_subnet" "transit_gateway_attachment_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.transit_gateway_attachment_subnet_a_cidr
  availability_zone = local.az_a
  tags              = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-a" })
}

resource "aws_subnet" "transit_gateway_attachment_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.transit_gateway_attachment_subnet_b_cidr
  availability_zone = local.az_b
  tags              = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-b" })
}

#
# NAT GATEWAYS
#
resource "aws_eip" "nat_gateway_a" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-gateway-eni-a" })

  depends_on = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_nat_gateway" "nat_gateway_a" {
  allocation_id = aws_eip.nat_gateway_a.allocation_id
  subnet_id     = aws_subnet.public_a.id
  tags          = merge(var.tags, { Name = "${var.name}-nat-gateway-a" })
}

resource "aws_eip" "nat_gateway_b" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-gateway-eni-b" })

  depends_on = [aws_internet_gateway_attachment.attach_igw]
}

resource "aws_nat_gateway" "nat_gateway_b" {
  allocation_id = aws_eip.nat_gateway_b.allocation_id
  subnet_id     = aws_subnet.public_b.id
  tags          = merge(var.tags, { Name = "${var.name}-nat-gateway-b" })
}

#
# ROUTE TABLES
#
resource "aws_route_table" "application_subnet_a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-subnet-a-rt" })
}

resource "aws_route_table_association" "application_a" {
  subnet_id      = aws_subnet.application_a.id
  route_table_id = aws_route_table.application_subnet_a.id
}

resource "aws_route_table" "application_subnet_b" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-subnet-b-rt" })
}

resource "aws_route_table_association" "application_b" {
  subnet_id      = aws_subnet.application_b.id
  route_table_id = aws_route_table.application_subnet_b.id
}

resource "aws_route_table" "transit_gateway_attachment" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-tgw-attach-subnet-rt" })
}

resource "aws_route_table_association" "transit_gateway_attachment_a" {
  subnet_id      = aws_subnet.transit_gateway_attachment_a.id
  route_table_id = aws_route_table.transit_gateway_attachment.id
}

resource "aws_route_table_association" "transit_gateway_attachment_b" {
  subnet_id      = aws_subnet.transit_gateway_attachment_b.id
  route_table_id = aws_route_table.transit_gateway_attachment.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  # Name is not prefixed with pName in the source template
  tags = merge(var.tags, { Name = "public-subnet-rt" })
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

#
# TRANSIT GATEWAY ATTACHMENT / ROUTING
# The transit gateway lives in the transit account and is shared to this account via RAM.
#
resource "aws_ec2_transit_gateway_vpc_attachment" "transit_gateway_attachment" {
  subnet_ids = [
    aws_subnet.transit_gateway_attachment_a.id,
    aws_subnet.transit_gateway_attachment_b.id,
  ]
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.vpc.id
  tags               = merge(var.tags, { Name = "${var.name}-tgw-attachment" })
}

resource "aws_route" "application_subnet_a_rt_nat_gateway_route" {
  route_table_id         = aws_route_table.application_subnet_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_a.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

resource "aws_route" "application_subnet_a_rt_tgw_route01" {
  route_table_id         = aws_route_table.application_subnet_a.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

resource "aws_route" "application_subnet_b_rt_nat_gateway_route" {
  route_table_id         = aws_route_table.application_subnet_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_b.id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

resource "aws_route" "application_subnet_b_rt_tgw_route01" {
  route_table_id         = aws_route_table.application_subnet_b.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

resource "aws_route" "public_rt_igw_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

  depends_on = [aws_internet_gateway_attachment.attach_igw]
}
