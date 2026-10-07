# Source: source/repositories/compliant-framework-management-services-core/templates/service-catalog/portfolio.yml
# Product artifacts (CloudFormation by definition): products/ (copied from templates/service-catalog/tenant-services/**
# and compliant-framework-transit-core/templates/transit-attach-tenant.yml)

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  # Former pS3Region (the pipeline passed e.g. "s3-us-gov-west-1"); used to build https://<bucket>.<label>.amazonaws.com/<key>
  templates_s3_region = coalesce(var.templates_s3_region, "s3.${local.region}")
  templates_base_url  = "https://${var.templates_bucket_name}.${local.templates_s3_region}.amazonaws.com"

  # Object keys are fixed: the product templates hard-code these paths (<repo name>/<path in repo>).
  product_objects = {
    tenant_two_tier_vpc_product = {
      key    = "compliant-framework-management-services-core/templates/service-catalog/tenant-services/tenant-two-tier-vpc/V1.0.0/tenant-two-tier-vpc-product.yml"
      source = "${path.module}/products/tenant-two-tier-vpc/V1.0.0/tenant-two-tier-vpc-product.yml"
    }
    tenant_two_tier_vpc = {
      key    = "compliant-framework-management-services-core/templates/service-catalog/tenant-services/tenant-two-tier-vpc/V1.0.0/tenant-two-tier-vpc.yml"
      source = "${path.module}/products/tenant-two-tier-vpc/V1.0.0/tenant-two-tier-vpc.yml"
    }
  }

  transit_objects = var.upload_transit_attach_tenant_template ? {
    transit_attach_tenant = {
      key    = "compliant-framework-transit-core/templates/transit-attach-tenant.yml"
      source = "${path.module}/products/transit-attach-tenant.yml"
    }
  } : {}
}

#
# SSM parameters read by the product template (pS3Bucket / pS3Region defaults)
#
resource "aws_ssm_parameter" "templates_s3_bucket_name" {
  name  = "/compliant/framework/management-services/s3/environment/bucket-name"
  type  = "String"
  value = var.templates_bucket_name
  tags  = var.tags
}

resource "aws_ssm_parameter" "templates_s3_region" {
  name  = "/compliant/framework/management-services/s3/region"
  type  = "String"
  value = local.templates_s3_region
  tags  = var.tags
}

#
# Product template artifacts
#
resource "aws_s3_object" "templates" {
  for_each = merge(local.product_objects, local.transit_objects)

  bucket       = var.templates_bucket_name
  key          = each.value.key
  source       = each.value.source
  source_hash  = filemd5(each.value.source)
  content_type = "application/x-yaml"
  tags         = var.tags
}

#
# CfnRunner Lambda (service token of the product's custom resources)
#
data "aws_iam_policy_document" "cfn_runner_lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Fixed role name kept from the source template (cfn_nag W28)
resource "aws_iam_role" "cfn_runner_lambda" {
  name               = "CompliantFrameworkCfnRunnerRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.cfn_runner_lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "cfn_runner_lambda_cloudwatch_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.cfn_runner_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*:*"
    }]
  })
}

resource "aws_iam_role_policy" "cfn_runner_lambda_sts_assume_role" {
  name = "sts-assume-role"
  role = aws_iam_role.cfn_runner_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sts:AssumeRole"]
      Resource = "arn:${local.partition}:iam::*:role/${var.cfn_runner_account_access_role}"
    }]
  })
}

data "archive_file" "cfn_runner" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/cfn_runner"
  output_path = "${path.module}/.build/cfn_runner.zip"
}

resource "aws_lambda_function" "cfn_runner" {
  function_name    = "CompliantFramework-CfnRunner"
  role             = aws_iam_role.cfn_runner_lambda.arn
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  timeout          = 900
  filename         = data.archive_file.cfn_runner.output_path
  source_code_hash = data.archive_file.cfn_runner.output_base64sha256

  environment {
    variables = {
      PARTITION                      = local.partition
      CFN_RUNNER_ACCOUNT_ACCESS_ROLE = var.cfn_runner_account_access_role
    }
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy.cfn_runner_lambda_cloudwatch_logs]
}

resource "aws_lambda_permission" "cfn_runner" {
  statement_id  = "AllowCloudFormationInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cfn_runner.function_name
  principal     = "cloudformation.amazonaws.com"
}

#
# Service Catalog portfolio / product
#
resource "aws_servicecatalog_portfolio" "tenant_services" {
  name          = "Compliant Framework - Tenant Services"
  description   = "This portfolio provides products that can be used to deploy resources into tenant accounts"
  provider_name = "Compliant Framework"
  tags          = var.tags
}

resource "aws_servicecatalog_product" "tenant_two_tier_vpc_v100" {
  name        = "Two Tier VPC"
  description = "Initializes a two-tier VPC in a tenant account"
  distributor = "Compliant Framework"
  owner       = "Compliant Framework"
  type        = "CLOUD_FORMATION_TEMPLATE"
  tags        = var.tags

  provisioning_artifact_parameters {
    name                        = "v1.0.0"
    description                 = "This initial version of this product"
    type                        = "CLOUD_FORMATION_TEMPLATE"
    template_url                = "${local.templates_base_url}/${aws_s3_object.templates["tenant_two_tier_vpc_product"].key}"
    disable_template_validation = false
  }

  # The product template references the nested template, the transit template and the Lambda at launch time
  depends_on = [aws_s3_object.templates, aws_lambda_permission.cfn_runner]
}

resource "aws_servicecatalog_product_portfolio_association" "tenant_two_tier_vpc" {
  portfolio_id = aws_servicecatalog_portfolio.tenant_services.id
  product_id   = aws_servicecatalog_product.tenant_two_tier_vpc_v100.id
}

# Not in the source template (access was granted out of band); optional.
resource "aws_servicecatalog_principal_portfolio_association" "this" {
  for_each = toset(var.portfolio_principal_arns)

  portfolio_id   = aws_servicecatalog_portfolio.tenant_services.id
  principal_arn  = each.value
  principal_type = "IAM"
}

# Not in the source template (products launched with the end user's permissions); optional.
resource "aws_servicecatalog_constraint" "launch" {
  count = var.launch_role_arn == null ? 0 : 1

  description  = "Launch role for the Two Tier VPC product"
  portfolio_id = aws_servicecatalog_portfolio.tenant_services.id
  product_id   = aws_servicecatalog_product.tenant_two_tier_vpc_v100.id
  type         = "LAUNCH"
  parameters   = jsonencode({ RoleArn = var.launch_role_arn })

  depends_on = [aws_servicecatalog_product_portfolio_association.tenant_two_tier_vpc]
}
