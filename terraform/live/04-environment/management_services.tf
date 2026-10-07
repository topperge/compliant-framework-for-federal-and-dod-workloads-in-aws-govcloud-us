# Management Services account: management-services-logging.yml and
# management-services-init.yml (source/repositories/compliant-framework-management-services-core).

module "management_services_logging" {
  source    = "../../modules/management-services-logging"
  providers = { aws = aws.management_services }

  principal_org_id                    = data.aws_organizations_organization.this.id
  logging_account_id                  = local.logging_account_id
  consolidated_logs_s3_bucket_cmk_arn = data.aws_ssm_parameter.consolidated_logs_cmk_arn.value
  primary_region                      = local.primary_region
  tags                                = local.tags
}

# The CloudFormation version created this only with the Directory VPC, but the
# Service Catalog portfolio always needs a template bucket, so it is always
# deployed here.
module "assets_bucket" {
  source    = "../../modules/management-services-assets-bucket"
  providers = { aws = aws.management_services }

  principal_org_id = data.aws_organizations_organization.this.id
  tags             = local.tags
}

module "management_services_vpc" {
  source    = "../../modules/management-services-vpc"
  providers = { aws = aws.management_services }

  transit_gateway_id                       = module.transit_gateway.transit_gateway_id
  logging_bucket_arn                       = module.management_services_logging.flow_logs_bucket_arn
  vpc_cidr                                 = local.ms.management_services_vpc.vpc_cidr
  instance_tenancy                         = local.ms.management_services_vpc.instance_tenancy
  application_subnet_a_cidr                = local.ms.management_services_vpc.application_subnet_a_cidr
  application_subnet_b_cidr                = local.ms.management_services_vpc.application_subnet_b_cidr
  data_subnet_a_cidr                       = local.ms.management_services_vpc.data_subnet_a_cidr
  data_subnet_b_cidr                       = local.ms.management_services_vpc.data_subnet_b_cidr
  transit_gateway_attachment_subnet_a_cidr = local.ms.management_services_vpc.transit_gateway_attachment_subnet_a_cidr
  transit_gateway_attachment_subnet_b_cidr = local.ms.management_services_vpc.transit_gateway_attachment_subnet_b_cidr
  tags                                     = local.tags

  # The attachment must exist after the RAM share is accepted (org sharing).
  depends_on = [module.transit_gateway]
}

module "directory_vpc" {
  source    = "../../modules/directory-vpc"
  providers = { aws = aws.management_services }
  count     = local.ms.enable_directory_vpc ? 1 : 0

  transit_gateway_id                       = module.transit_gateway.transit_gateway_id
  logging_bucket_arn                       = module.management_services_logging.flow_logs_bucket_arn
  vpc_cidr                                 = local.ms.directory_vpc.vpc_cidr
  instance_tenancy                         = local.ms.directory_vpc.instance_tenancy
  application_subnet_a_cidr                = local.ms.directory_vpc.application_subnet_a_cidr
  application_subnet_b_cidr                = local.ms.directory_vpc.application_subnet_b_cidr
  data_subnet_a_cidr                       = local.ms.directory_vpc.data_subnet_a_cidr
  data_subnet_b_cidr                       = local.ms.directory_vpc.data_subnet_b_cidr
  transit_gateway_attachment_subnet_a_cidr = local.ms.directory_vpc.transit_gateway_attachment_subnet_a_cidr
  transit_gateway_attachment_subnet_b_cidr = local.ms.directory_vpc.transit_gateway_attachment_subnet_b_cidr
  tags                                     = local.tags

  depends_on = [module.transit_gateway]
}

module "external_access_vpc" {
  source    = "../../modules/external-access-vpc"
  providers = { aws = aws.management_services }
  count     = local.ms.enable_external_access_vpc ? 1 : 0

  transit_gateway_id                       = module.transit_gateway.transit_gateway_id
  logging_bucket_arn                       = module.management_services_logging.flow_logs_bucket_arn
  vpc_cidr                                 = local.ms.external_access_vpc.vpc_cidr
  instance_tenancy                         = local.ms.external_access_vpc.instance_tenancy
  public_subnet_a_cidr                     = local.ms.external_access_vpc.public_subnet_a_cidr
  public_subnet_b_cidr                     = local.ms.external_access_vpc.public_subnet_b_cidr
  application_subnet_a_cidr                = local.ms.external_access_vpc.application_subnet_a_cidr
  application_subnet_b_cidr                = local.ms.external_access_vpc.application_subnet_b_cidr
  transit_gateway_attachment_subnet_a_cidr = local.ms.external_access_vpc.transit_gateway_attachment_subnet_a_cidr
  transit_gateway_attachment_subnet_b_cidr = local.ms.external_access_vpc.transit_gateway_attachment_subnet_b_cidr
  tags                                     = local.tags

  depends_on = [module.transit_gateway]
}

module "service_catalog_portfolio" {
  source    = "../../modules/service-catalog-portfolio"
  providers = { aws = aws.management_services }

  templates_bucket_name    = module.assets_bucket.bucket_name
  portfolio_principal_arns = try(local.ms.service_catalog_principal_arns, [])
  tags                     = local.tags
}
