#
# SSM parameters (same names as the source template)
#
locals {
  ssm_prefix = "/compliant/framework/management-services/management-services-vpc"

  ssm_parameters = {
    vpc_id                                 = { name = "id", value = aws_vpc.vpc.id }
    application_subnet_a_id                = { name = "application-subnet/a/id", value = aws_subnet.application_a.id }
    application_subnet_b_id                = { name = "application-subnet/b/id", value = aws_subnet.application_b.id }
    application_rt_a                       = { name = "application-subnet/route-table/a/id", value = aws_route_table.application_a.id }
    application_rt_b                       = { name = "application-subnet/route-table/b/id", value = aws_route_table.application_b.id }
    data_subnet_a_id                       = { name = "data-subnet/a/id", value = aws_subnet.data_a.id }
    data_subnet_b_id                       = { name = "data-subnet/b/id", value = aws_subnet.data_b.id }
    data_rt_a                              = { name = "data-subnet/route-table/a/id", value = aws_route_table.data_a.id }
    data_rt_b                              = { name = "data-subnet/route-table/b/id", value = aws_route_table.data_b.id }
    transit_gateway_attachment_subnet_a_id = { name = "tgw-attach-subnet/a/id", value = aws_subnet.transit_gateway_attachment_a.id }
    transit_gateway_attachment_subnet_b_id = { name = "tgw-attach-subnet/b/id", value = aws_subnet.transit_gateway_attachment_b.id }
    transit_gateway_attachment_rt_id       = { name = "tgw-attach-subnet/route-table/a/id", value = aws_route_table.transit_gateway_attachment.id }
    # NOTE: the source template stores the TGW *attachment* id under ".../route-table/b/id"; kept verbatim for compatibility.
    transit_gateway_attachment_id = { name = "tgw-attach-subnet/route-table/b/id", value = aws_ec2_transit_gateway_vpc_attachment.transit_gateway_attachment.id }
  }
}

resource "aws_ssm_parameter" "this" {
  for_each = local.ssm_parameters

  name  = "${local.ssm_prefix}/${each.value.name}"
  type  = "String"
  value = each.value.value
  tags  = var.tags
}
