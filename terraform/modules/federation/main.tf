# Source: source/repositories/compliant-framework-security-baseline/templates/federation/federation.yml
# SAML-federated IAM roles. The SAML provider itself is NOT created here (the source template only references
# arn:<partition>:iam::<account>:saml-provider/<federation_name>).

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition         = data.aws_partition.current.partition
  saml_provider_arn = "arn:${local.partition}:iam::${data.aws_caller_identity.current.account_id}:saml-provider/${var.federation_name}"

  # Map key = CFN logical id in snake_case (without the leading "r").
  federation_roles = {
    administrator_access_role = {
      suffix     = "AdministratorAccess"
      policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
    }
    system_administrator_role = {
      suffix     = "SystemAdministrator"
      policy_arn = "arn:${local.partition}:iam::aws:policy/job-function/SystemAdministrator"
    }
    view_only_access_role = {
      suffix     = "ViewOnlyAccess"
      policy_arn = "arn:${local.partition}:iam::aws:policy/job-function/ViewOnlyAccess"
    }
  }
}

resource "aws_iam_role" "federation" {
  for_each = local.federation_roles

  name                 = "${var.federation_name}-${each.value.suffix}"
  path                 = "/"
  max_session_duration = 21600 # 6 hours in seconds
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.saml_provider_arn }
      Action    = "sts:AssumeRoleWithSAML"
      Condition = {
        StringEquals = { "SAML:aud" = var.saml_endpoint }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "federation" {
  for_each = local.federation_roles

  role       = aws_iam_role.federation[each.key].name
  policy_arn = each.value.policy_arn
}
