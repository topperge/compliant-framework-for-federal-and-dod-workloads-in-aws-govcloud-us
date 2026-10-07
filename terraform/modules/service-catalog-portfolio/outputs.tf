# The source template defines no Outputs; these are provided for composition.

output "portfolio_id" {
  description = "ID of the 'Compliant Framework - Tenant Services' portfolio."
  value       = aws_servicecatalog_portfolio.tenant_services.id
}

output "tenant_two_tier_vpc_product_id" {
  description = "ID of the 'Two Tier VPC' product."
  value       = aws_servicecatalog_product.tenant_two_tier_vpc_v100.id
}

output "cfn_runner_lambda_arn" {
  description = "ARN of the CompliantFramework-CfnRunner Lambda function."
  value       = aws_lambda_function.cfn_runner.arn
}

output "cfn_runner_role_arn" {
  description = "ARN of the CompliantFrameworkCfnRunnerRole IAM role."
  value       = aws_iam_role.cfn_runner_lambda.arn
}

output "product_template_url" {
  description = "URL of the Two Tier VPC product template (provisioning artifact v1.0.0)."
  value       = "${local.templates_base_url}/${aws_s3_object.templates["tenant_two_tier_vpc_product"].key}"
}
