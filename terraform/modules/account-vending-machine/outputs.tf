output "portfolio_id" {
  description = "ID of the 'Compliant Framework - Tenant Services' Service Catalog portfolio."
  value       = aws_servicecatalog_portfolio.portfolio.id
}

output "product_id" {
  description = "ID of the 'Account Vending Machine for AWS GovCloud (US)' Service Catalog product."
  value       = aws_servicecatalog_product.avm_for_govcloud_product_v100.id
}

output "product_template_url" {
  description = "HTTPS URL of the product CloudFormation template in S3."
  value       = local.template_url
}

output "template_bucket_name" {
  description = "Name of the S3 bucket holding the product template."
  value       = local.template_bucket_name
}

output "lambda_function_arns" {
  description = "ARNs of the AVM custom-resource Lambdas, keyed by short name (get_ou, create_govcloud_account, invite_govcloud_account, move_account)."
  value       = { for k, f in aws_lambda_function.avm : k => f.arn }
}

output "lambda_role_arns" {
  description = "ARNs of the AVM Lambda execution roles, keyed by short name."
  value       = { for k, r in aws_iam_role.avm : k => r.arn }
}
