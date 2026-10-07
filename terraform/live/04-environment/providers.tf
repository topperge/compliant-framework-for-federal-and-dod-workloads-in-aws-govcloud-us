locals {
  config = yamldecode(file(coalesce(var.config_file, "${path.root}/../../config/framework.yaml")))

  account_access_role = try(local.config.account_access_role_name, "CompliantFrameworkAccountAccessRole")
  central_account_id  = tostring(local.config.central.account_id)
  logging_account_id  = tostring(local.config.logging.account_id)
  primary_region      = local.config.primary_region

  env     = local.config.environments[var.environment]
  region  = local.env.region
  transit = local.env.transit
  ms      = local.env.management_services
  tenants = try(local.env.tenants, [])

  transit_account_id = tostring(local.transit.account_id)
  ms_account_id      = tostring(local.ms.account_id)

  tags = merge(local.config.tags, { Environment = var.environment })
}

provider "aws" {
  alias  = "central"
  region = local.region

  allowed_account_ids = [local.central_account_id]

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "transit"
  region = local.region

  allowed_account_ids = [local.transit_account_id]

  assume_role {
    role_arn     = "arn:${data.aws_partition.current.partition}:iam::${local.transit_account_id}:role/${local.account_access_role}"
    session_name = "compliant-framework-terraform"
  }

  default_tags {
    tags = local.tags
  }
}

provider "aws" {
  alias  = "management_services"
  region = local.region

  allowed_account_ids = [local.ms_account_id]

  assume_role {
    role_arn     = "arn:${data.aws_partition.current.partition}:iam::${local.ms_account_id}:role/${local.account_access_role}"
    session_name = "compliant-framework-terraform"
  }

  default_tags {
    tags = local.tags
  }
}

data "aws_partition" "current" {
  provider = aws.central
}

data "aws_organizations_organization" "this" {
  provider = aws.central
}

# Written by the core layer (03-core).
data "aws_ssm_parameter" "consolidated_logs_cmk_arn" {
  provider = aws.central
  name     = "/compliant/framework/consolidated-logs/cmk/arn"
}

resource "terraform_data" "partition_check" {
  lifecycle {
    precondition {
      condition     = data.aws_partition.current.partition == try(local.config.partition, "aws-us-gov")
      error_message = "Credentials are for partition ${data.aws_partition.current.partition} but the config targets ${try(local.config.partition, "aws-us-gov")}."
    }
  }
}
