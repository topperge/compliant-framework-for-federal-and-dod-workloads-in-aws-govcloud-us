# Transit account: transit-init.yml, transit-gateway-route-tables.yml and the
# per-tenant transit-attach-tenant.yml (source/repositories/compliant-framework-transit-core).

locals {
  # Flow logs of transit VPCs go to the Management Services account's bucket.
  flow_logs_bucket_arn = "arn:${data.aws_partition.current.partition}:s3:::flow-logs-${local.ms_account_id}-${local.region}"

  enable_virtual_firewall = local.transit.enable_virtual_firewall
  enable_vpc_firewall     = local.transit.enable_vpc_firewall
  firewall_vpc            = try(local.transit.firewall_vpc, {})
  dmz_vpc                 = try(local.transit.dmz_vpc, {})
  inspection_vpc          = try(local.transit.inspection_vpc, {})
}

module "transit_gateway" {
  source    = "../../modules/transit-gateway"
  providers = { aws = aws.transit }

  transit_gateway_amazon_side_asn = local.transit.transit_gateway_amazon_side_asn
  central_account_id              = local.central_account_id
  principal_org_id                = data.aws_organizations_organization.this.id
  enable_directory_vpc            = local.ms.enable_directory_vpc
  enable_external_access_vpc      = local.ms.enable_external_access_vpc
  enable_vpc_firewall             = local.enable_vpc_firewall
  enable_virtual_firewall         = local.enable_virtual_firewall
  tags                            = local.tags
}

#
# Virtual firewall (VDSS) VPC + VPN attachments to the firewall appliances
#
module "firewall_vpc" {
  source    = "../../modules/transit-firewall-vpc"
  providers = { aws = aws.transit }
  count     = local.enable_virtual_firewall ? 1 : 0

  transit_gateway_id                       = module.transit_gateway.transit_gateway_id
  logging_bucket_arn                       = local.flow_logs_bucket_arn
  vpc_cidr                                 = local.firewall_vpc.vpc_cidr
  vpc_nipr_cidr                            = local.firewall_vpc.vpc_nipr_cidr
  instance_tenancy                         = local.firewall_vpc.instance_tenancy
  enable_igw                               = local.firewall_vpc.enable_igw
  attach_tgw                               = local.firewall_vpc.attach_tgw
  external_subnet_a_cidr                   = local.firewall_vpc.external_subnet_a_cidr
  external_subnet_b_cidr                   = local.firewall_vpc.external_subnet_b_cidr
  internal_subnet_a_cidr                   = local.firewall_vpc.internal_subnet_a_cidr
  internal_subnet_b_cidr                   = local.firewall_vpc.internal_subnet_b_cidr
  management_subnet_a_cidr                 = local.firewall_vpc.management_subnet_a_cidr
  management_subnet_b_cidr                 = local.firewall_vpc.management_subnet_b_cidr
  transit_gateway_attachment_subnet_a_cidr = local.firewall_vpc.transit_gateway_attachment_subnet_a_cidr
  transit_gateway_attachment_subnet_b_cidr = local.firewall_vpc.transit_gateway_attachment_subnet_b_cidr
  tags                                     = local.tags

  # Flow logs are delivered to the Management Services bucket.
  depends_on = [module.management_services_logging]
}

module "firewall_vpn_attachment" {
  source    = "../../modules/transit-vpn-attachment"
  providers = { aws = aws.transit }
  count     = local.enable_virtual_firewall ? 1 : 0

  transit_gateway_id            = module.transit_gateway.transit_gateway_id
  customer_gateway_a_ip_address = module.firewall_vpc[0].firewall_a_internal_eni_public_ip_address
  customer_gateway_b_ip_address = module.firewall_vpc[0].firewall_b_internal_eni_public_ip_address
  customer_gateway_a_bgp_asn    = tostring(local.firewall_vpc.firewall_a_asn)
  customer_gateway_b_bgp_asn    = tostring(local.firewall_vpc.firewall_b_asn)
  tags                          = local.tags
}

#
# VPC firewall (DMZ + inspection VPCs)
#
module "dmz_vpc" {
  source    = "../../modules/transit-dmz-vpc"
  providers = { aws = aws.transit }
  count     = local.enable_vpc_firewall ? 1 : 0

  transit_gateway_id                       = module.transit_gateway.transit_gateway_id
  logging_bucket_arn                       = local.flow_logs_bucket_arn
  central_account_id                       = local.central_account_id
  principal_org_id                         = data.aws_organizations_organization.this.id
  vpc_cidr                                 = try(local.dmz_vpc.vpc_cidr, null)
  instance_tenancy                         = try(local.dmz_vpc.instance_tenancy, "default")
  public_subnet_a_cidr                     = try(local.dmz_vpc.public_subnet_a_cidr, null)
  public_subnet_b_cidr                     = try(local.dmz_vpc.public_subnet_b_cidr, null)
  transit_gateway_attachment_subnet_a_cidr = try(local.dmz_vpc.transit_gateway_attachment_subnet_a_cidr, null)
  transit_gateway_attachment_subnet_b_cidr = try(local.dmz_vpc.transit_gateway_attachment_subnet_b_cidr, null)
  tags                                     = local.tags

  depends_on = [module.management_services_logging]
}

module "inspection_vpc" {
  source    = "../../modules/transit-inspection-vpc"
  providers = { aws = aws.transit }
  count     = local.enable_vpc_firewall ? 1 : 0

  transit_gateway_id                       = module.transit_gateway.transit_gateway_id
  logging_bucket_arn                       = local.flow_logs_bucket_arn
  vpc_cidr                                 = try(local.inspection_vpc.vpc_cidr, null)
  instance_tenancy                         = try(local.inspection_vpc.instance_tenancy, "default")
  public_subnet_a_cidr                     = try(local.inspection_vpc.public_subnet_a_cidr, null)
  public_subnet_b_cidr                     = try(local.inspection_vpc.public_subnet_b_cidr, null)
  firewall_subnet_a_cidr                   = try(local.inspection_vpc.firewall_subnet_a_cidr, null)
  firewall_subnet_b_cidr                   = try(local.inspection_vpc.firewall_subnet_b_cidr, null)
  transit_gateway_attachment_subnet_a_cidr = try(local.inspection_vpc.transit_gateway_attachment_subnet_a_cidr, null)
  transit_gateway_attachment_subnet_b_cidr = try(local.inspection_vpc.transit_gateway_attachment_subnet_b_cidr, null)
  tags                                     = local.tags

  depends_on = [module.management_services_logging]
}

#
# Transit Gateway route tables (transit-gateway-route-tables.yml)
#
module "transit_gateway_route_tables" {
  source    = "../../modules/transit-gateway-route-tables"
  providers = { aws = aws.transit }

  enable_virtual_firewall    = local.enable_virtual_firewall
  enable_vpc_firewall        = local.enable_vpc_firewall
  enable_directory_vpc       = local.ms.enable_directory_vpc
  enable_external_access_vpc = local.ms.enable_external_access_vpc
  attach_firewall_vpc        = try(local.firewall_vpc.attach_tgw, true)

  internal_route_table_id            = module.transit_gateway.transit_gateway_internal_route_table_id
  management_services_route_table_id = module.transit_gateway.transit_gateway_management_services_route_table_id
  directory_route_table_id           = module.transit_gateway.transit_gateway_directory_route_table_id
  external_access_route_table_id     = module.transit_gateway.transit_gateway_external_access_route_table_id
  firewall_route_table_id            = module.transit_gateway.transit_gateway_firewall_route_table_id
  dmz_route_table_id                 = module.transit_gateway.transit_gateway_dmz_route_table_id
  inspection_route_table_id          = module.transit_gateway.transit_gateway_inspection_route_table_id

  management_services_vpc_tgw_attachment_id = module.management_services_vpc.transit_gateway_attachment_id
  directory_vpc_tgw_attachment_id           = one(module.directory_vpc[*].transit_gateway_attachment_id)
  external_access_vpc_tgw_attachment_id     = one(module.external_access_vpc[*].transit_gateway_attachment_id)
  firewall_vpc_tgw_attachment_id            = one(module.firewall_vpc[*].firewall_vpc_transit_gateway_attachment_id)
  inspection_vpc_tgw_attachment_id          = one(module.inspection_vpc[*].transit_gateway_attachment_id)
  dmz_vpc_tgw_attachment_id                 = one(module.dmz_vpc[*].transit_gateway_attachment_id)
}

#
# Tenant (plugin / Mission App) VPC attachments. Applied with the transit
# account provider: only the TGW owner can associate/propagate attachments.
#
module "tenant_attachment" {
  source    = "../../modules/transit-attach-tenant"
  providers = { aws = aws.transit }
  for_each = {
    for t in local.tenants : t.name => t
    if try(t.transit_gateway_attachment_id, null) != null
  }

  tgw_attachment_id          = each.value.transit_gateway_attachment_id
  enable_virtual_firewall    = local.enable_virtual_firewall
  enable_vpc_firewall        = local.enable_vpc_firewall
  enable_directory_vpc       = local.ms.enable_directory_vpc
  enable_external_access_vpc = local.ms.enable_external_access_vpc

  internal_route_table_id            = module.transit_gateway.transit_gateway_internal_route_table_id
  management_services_route_table_id = module.transit_gateway.transit_gateway_management_services_route_table_id
  directory_route_table_id           = module.transit_gateway.transit_gateway_directory_route_table_id
  firewall_route_table_id            = module.transit_gateway.transit_gateway_firewall_route_table_id
  inspection_route_table_id          = module.transit_gateway.transit_gateway_inspection_route_table_id
  external_access_route_table_id     = module.transit_gateway.transit_gateway_external_access_route_table_id

  depends_on = [module.transit_gateway_route_tables]
}
