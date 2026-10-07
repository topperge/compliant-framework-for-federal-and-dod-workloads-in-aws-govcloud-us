terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }

  # Partial configuration. With partition = "aws-us-gov" the commercial payer
  # credentials cannot read the GovCloud state bucket, so pass a commercial-side
  # bucket (backend-commercial.hcl). With partition = "aws" use backend.hcl.
  backend "s3" {}
}
