# Source: source/repositories/compliant-framework-transit-core/templates/transit-vpn-attachment.yml
# (plus /compliant/framework/transit/firewall-vpc/vpn-connection/{a,b}/id from transit-init.yml)

resource "aws_customer_gateway" "customer_gateway_a" {
  bgp_asn    = var.customer_gateway_a_bgp_asn
  ip_address = var.customer_gateway_a_ip_address
  type       = "ipsec.1"
  tags       = merge(var.tags, { Name = "${var.name}-a-cgw" })
}

resource "aws_vpn_connection" "vpn_connection_a" {
  customer_gateway_id = aws_customer_gateway.customer_gateway_a.id
  transit_gateway_id  = var.transit_gateway_id
  type                = "ipsec.1"
  tags                = merge(var.tags, { Name = "${var.name}-a-vpn" })
}

resource "aws_customer_gateway" "customer_gateway_b" {
  bgp_asn    = var.customer_gateway_b_bgp_asn
  ip_address = var.customer_gateway_b_ip_address
  type       = "ipsec.1"
  tags       = merge(var.tags, { Name = "${var.name}-b-cgw" })
}

resource "aws_vpn_connection" "vpn_connection_b" {
  customer_gateway_id = aws_customer_gateway.customer_gateway_b.id
  transit_gateway_id  = var.transit_gateway_id
  type                = "ipsec.1"
  tags                = merge(var.tags, { Name = "${var.name}-b-vpn" })
}

#
# Store values into SSM Parameter Store (from transit-init.yml)
#
resource "aws_ssm_parameter" "firewall_vpn_connection_a_id" {
  name  = "/compliant/framework/transit/firewall-vpc/vpn-connection/a/id"
  type  = "String"
  value = aws_vpn_connection.vpn_connection_a.id
  tags  = var.tags
}

resource "aws_ssm_parameter" "firewall_vpn_connection_b_id" {
  name  = "/compliant/framework/transit/firewall-vpc/vpn-connection/b/id"
  type  = "String"
  value = aws_vpn_connection.vpn_connection_b.id
  tags  = var.tags
}
