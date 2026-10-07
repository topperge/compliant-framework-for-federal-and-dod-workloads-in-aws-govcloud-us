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

  # Partial configuration: the commercial payer account cannot read the GovCloud
  # state bucket with the same credentials, so pass a commercial-side bucket,
  # or use a local backend, via -backend-config.
  backend "s3" {}
}
