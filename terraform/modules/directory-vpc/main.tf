# Source: source/repositories/compliant-framework-management-services-core/templates/management-services-directory-vpc.yml

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
# SUBNETS
#
resource "aws_subnet" "application_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.application_subnet_a_cidr
  availability_zone = local.az_a
  tags              = merge(var.tags, { Name = "${var.name}-app-subnet-a" })
}

resource "aws_subnet" "application_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.application_subnet_b_cidr
  availability_zone = local.az_b
  tags              = merge(var.tags, { Name = "${var.name}-app-subnet-b" })
}

resource "aws_subnet" "data_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.data_subnet_a_cidr
  availability_zone = local.az_a
  tags              = merge(var.tags, { Name = "${var.name}-data-subnet-a" })
}

resource "aws_subnet" "data_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.data_subnet_b_cidr
  availability_zone = local.az_b
  tags              = merge(var.tags, { Name = "${var.name}-data-subnet-b" })
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
# ROUTE TABLES
#
resource "aws_route_table" "application_a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-app-subnet-rt-a" })
}

resource "aws_route_table_association" "application_a" {
  subnet_id      = aws_subnet.application_a.id
  route_table_id = aws_route_table.application_a.id
}

resource "aws_route_table" "application_b" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-app-subnet-rt-b" })
}

resource "aws_route_table_association" "application_b" {
  subnet_id      = aws_subnet.application_b.id
  route_table_id = aws_route_table.application_b.id
}

resource "aws_route_table" "data_a" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-data-subnet-rt-a" })
}

resource "aws_route_table_association" "data_a" {
  subnet_id      = aws_subnet.data_a.id
  route_table_id = aws_route_table.data_a.id
}

resource "aws_route_table" "data_b" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-data-subnet-rt-b" })
}

resource "aws_route_table_association" "data_b" {
  subnet_id      = aws_subnet.data_b.id
  route_table_id = aws_route_table.data_b.id
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

# Send All Traffic to TGW [App A]
resource "aws_route" "vpc_application_rt_a_tgw_route_rfc1918_route1" {
  route_table_id         = aws_route_table.application_a.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

# Send All Traffic to TGW [App B]
resource "aws_route" "vpc_application_rt_b_tgw_route_rfc1918_route1" {
  route_table_id         = aws_route_table.application_b.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment]
}

#
# VPC Endpoints
#
locals {
  endpoint_sg_rules = [
    { description = "All TCP", protocol = "tcp", from_port = 0, to_port = 65535 },
    { description = "All UDP", protocol = "udp", from_port = 0, to_port = 65535 },
    { description = "All ICMP", protocol = "icmp", from_port = -1, to_port = -1 },
  ]

  interface_endpoints = {
    ssm         = "ssm"
    ssmmessages = "ssmmessages"
    ec2messages = "ec2messages"
    efs         = "elasticfilesystem"
  }
}

# Allows all traffic from/to the VPC CIDR only (cfn_nag W27/W29 suppressed in source)
resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "${var.name}-vpc-endpoint-sg-"
  description = "Allow All"
  vpc_id      = aws_vpc.vpc.id
  tags        = var.tags

  dynamic "ingress" {
    for_each = local.endpoint_sg_rules
    content {
      description = ingress.value.description
      protocol    = ingress.value.protocol
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      cidr_blocks = [var.vpc_cidr]
    }
  }

  dynamic "egress" {
    for_each = local.endpoint_sg_rules
    content {
      description = egress.value.description
      protocol    = egress.value.protocol
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      cidr_blocks = [var.vpc_cidr]
    }
  }

  lifecycle {
    ignore_changes = [name, name_prefix]
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${local.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  subnet_ids          = [aws_subnet.application_a.id, aws_subnet.application_b.id]
  tags                = var.tags
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.application_a.id, aws_route_table.application_b.id]
  tags              = var.tags
}
