locals {
  config = yamldecode(file(coalesce(var.config_file, "${path.root}/../../config/framework.yaml")))

  account_access_role = try(local.config.account_access_role_name, "CompliantFrameworkAccountAccessRole")
  central_account_id  = tostring(local.config.central.account_id)
  logging_account_id  = tostring(local.config.logging.account_id)
  primary_region      = local.config.primary_region
  core_tags           = merge(local.config.tags, { Environment = "core" })
}

# Central (GovCloud organization management) account: the caller's credentials.
provider "aws" {
  alias  = "central"
  region = local.primary_region

  allowed_account_ids = [local.central_account_id]

  default_tags {
    tags = local.core_tags
  }
}

provider "aws" {
  alias  = "logging"
  region = local.primary_region

  allowed_account_ids = [local.logging_account_id]

  assume_role {
    role_arn     = "arn:${data.aws_partition.current.partition}:iam::${local.logging_account_id}:role/${local.account_access_role}"
    session_name = "compliant-framework-terraform"
  }

  default_tags {
    tags = local.core_tags
  }
}

data "aws_partition" "current" {
  provider = aws.central
}

data "aws_organizations_organization" "this" {
  provider = aws.central
}

resource "terraform_data" "partition_check" {
  lifecycle {
    precondition {
      condition     = data.aws_partition.current.partition == try(local.config.partition, "aws-us-gov")
      error_message = "Credentials are for partition ${data.aws_partition.current.partition} but the config targets ${try(local.config.partition, "aws-us-gov")}."
    }
  }
}
