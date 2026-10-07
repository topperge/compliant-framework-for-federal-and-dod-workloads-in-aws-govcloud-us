# Cross-account IAM roles created by the security baseline.

# Cross account access role to accept Security Hub invites
resource "aws_iam_role" "security_hub_access_role" {
  name = "SecurityHubAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = var.central_account_id }
      Action    = ["sts:AssumeRole"]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "security_hub_access_role" {
  name = "security-hub-accept-invite"
  role = aws_iam_role.security_hub_access_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "securityhub:AcceptInvitation",
        "securityhub:ListInvitations",
      ]
      Resource = "*"
    }]
  })
}

# AccessRole for CFN Runner - Has full administrative access to build new
# resources via the Service Catalog products in the Management Services
resource "aws_iam_role" "cfn_runner_account_access_role" {
  name = "CfnRunnerAccountAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:${local.partition}:iam::${var.management_services_account_id}:role/CompliantFrameworkCfnRunnerRole" }
      Action    = ["sts:AssumeRole"]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "cfn_runner_account_access_role" {
  name = "cfn-runner"
  role = aws_iam_role.cfn_runner_account_access_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

locals {
  # Roles assumable from the role of the same name in the central account.
  central_access_roles = {
    # This user has full access and can delegate permissions to every service and resource in AWS.
    administrators_access_role = {
      name       = "CompliantFrameworkAdministratorsAccessRole"
      policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
    }
    # Monitors accounts for compliance with security requirements; can access logs and events.
    security_auditors_access_role = {
      name       = "CompliantFrameworkSecurityAuditorsAccessRole"
      policy_arn = "arn:${local.partition}:iam::aws:policy/SecurityAudit"
    }
    # Can view a list of AWS resources and basic metadata across all services.
    view_only_access_role = {
      name       = "CompliantFrameworkViewOnlyAccessRole"
      policy_arn = "arn:${local.partition}:iam::aws:policy/job-function/ViewOnlyAccess"
    }
  }
}

resource "aws_iam_role" "central_access" {
  for_each = local.central_access_roles

  name = each.value.name
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:${local.partition}:iam::${var.central_account_id}:role/${each.value.name}" }
      Action    = ["sts:AssumeRole"]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "central_access" {
  for_each = local.central_access_roles

  role       = aws_iam_role.central_access[each.key].name
  policy_arn = each.value.policy_arn
}
