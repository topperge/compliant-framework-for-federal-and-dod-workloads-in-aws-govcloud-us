terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }

  # Intentionally local: this layer creates the remote state bucket used by
  # every other layer. Keep the generated terraform.tfstate safe (or migrate it
  # into the bucket afterwards with `terraform init -migrate-state`).
}
