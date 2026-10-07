# ---------------------------------------------------------------------------------------------------------------------
# Product template storage (replaces https://%%BUCKET_NAME%%-<region>.s3.amazonaws.com/%%SOLUTION_NAME%%/%%VERSION%%/)
# ---------------------------------------------------------------------------------------------------------------------
locals {
  template_bucket_name = coalesce(var.template_bucket_name, "compliant-framework-avm-templates-${local.account_id}-${local.region}")
  template_file        = "compliant-framework-govcloud-account-product-v1.0.0.yml"
  template_key         = "${var.template_key_prefix}${local.template_file}"
  template_url         = "https://${local.template_bucket_name}.s3.${local.region}.amazonaws.com/${local.template_key}"
}

resource "aws_s3_bucket" "templates" {
  count = var.create_template_bucket ? 1 : 0

  bucket        = local.template_bucket_name
  force_destroy = var.template_bucket_force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "templates" {
  count = var.create_template_bucket ? 1 : 0

  bucket = aws_s3_bucket.templates[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "templates" {
  count = var.create_template_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.templates[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "templates" {
  count = var.create_template_bucket ? 1 : 0

  bucket = aws_s3_bucket.templates[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "templates" {
  count = var.create_template_bucket ? 1 : 0

  bucket = aws_s3_bucket.templates[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "templates_bucket" {
  count = var.create_template_bucket ? 1 : 0

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.templates[0].arn,
      "${aws_s3_bucket.templates[0].arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "templates" {
  count = var.create_template_bucket ? 1 : 0

  bucket = aws_s3_bucket.templates[0].id
  policy = data.aws_iam_policy_document.templates_bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.templates]
}

# The product stays a CloudFormation template (Service Catalog CLOUD_FORMATION_TEMPLATE product).
resource "aws_s3_object" "product_template" {
  bucket       = var.create_template_bucket ? aws_s3_bucket.templates[0].id : local.template_bucket_name
  key          = local.template_key
  source       = "${path.module}/products/${local.template_file}"
  etag         = filemd5("${path.module}/products/${local.template_file}")
  content_type = "application/x-yaml"
  tags         = var.tags

  lifecycle {
    precondition {
      condition     = var.create_template_bucket || var.template_bucket_name != null
      error_message = "template_bucket_name is required when create_template_bucket is false."
    }
  }

  depends_on = [
    aws_s3_bucket_ownership_controls.templates,
    aws_s3_bucket_server_side_encryption_configuration.templates,
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Service Catalog portfolio / product
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_servicecatalog_portfolio" "portfolio" {
  name          = "Compliant Framework - Tenant Services"
  provider_name = "Compliant Framework"
  tags          = var.tags
}

resource "aws_servicecatalog_product" "avm_for_govcloud_product_v100" {
  name        = "Account Vending Machine for AWS GovCloud (US)"
  owner       = "Compliant Framework"
  distributor = "Compliant Framework"
  type        = "CLOUD_FORMATION_TEMPLATE"
  description = join("", [
    "Creates a new GovCloud account using the ",
    "CreateGovCloudAccount API. This product requires the creation of ",
    "AWS CLI Keys for the Central GovCloud account with the proper ",
    "permissions and stored as ",
    "${var.govcloud_access_key_id_parameter_name} and ",
    "${var.govcloud_secret_access_key_parameter_name} ",
    "into SSM Parameter Store. Please see the implementation guide ",
    "for more details on setting the IAM permissions",
  ])

  provisioning_artifact_parameters {
    name         = "v1.0.0"
    type         = "CLOUD_FORMATION_TEMPLATE"
    template_url = local.template_url
  }

  tags = var.tags

  # The template's custom resources invoke the Lambdas by their fixed names.
  depends_on = [
    aws_s3_object.product_template,
    aws_lambda_function.avm,
  ]
}

resource "aws_servicecatalog_product_portfolio_association" "avm_for_govcloud_v100" {
  portfolio_id = aws_servicecatalog_portfolio.portfolio.id
  product_id   = aws_servicecatalog_product.avm_for_govcloud_product_v100.id
}

resource "aws_servicecatalog_principal_portfolio_association" "portfolio" {
  for_each = toset(var.portfolio_principal_arns)

  portfolio_id  = aws_servicecatalog_portfolio.portfolio.id
  principal_arn = each.value
}
