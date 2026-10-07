# Source: source/repositories/compliant-framework-central-core/templates/security/security-iam-groups.yml
#
# Non-federated IAM groups, each allowed to assume a matching same-account role. Global IAM: deploy once per account.

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition = data.aws_partition.current.partition

  # Roles are trusted by the account itself (CFN Principal AWS: !Ref AWS::AccountId)
  same_account_trust = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:${local.partition}:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = ["sts:AssumeRole"]
    }]
  })
}

#
# Administrators: full access, can delegate permissions to every service and resource in AWS
#
resource "aws_iam_role" "administrators_access" {
  name               = "CompliantFrameworkAdministratorsAccessRole"
  path               = "/"
  assume_role_policy = local.same_account_trust
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "administrators_access" {
  role       = aws_iam_role.administrators_access.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group" "administrators" {
  name = "CompliantFrameworkAdministratorsGroup"
}

resource "aws_iam_group_policy" "administrators" {
  name  = "assume-role-policy"
  group = aws_iam_group.administrators.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sts:AssumeRole"]
      Resource = [aws_iam_role.administrators_access.arn]
    }]
  })
}

#
# Security auditors: monitor accounts for compliance, access logs and events to investigate potential breaches
#
resource "aws_iam_role" "security_auditors_access" {
  name               = "CompliantFrameworkSecurityAuditorsAccessRole"
  path               = "/"
  assume_role_policy = local.same_account_trust
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "security_auditors_access" {
  role       = aws_iam_role.security_auditors_access.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_group" "security_auditors" {
  name = "CompliantFrameworkSecurityAuditorsGroup"
}

resource "aws_iam_group_policy" "security_auditors" {
  name  = "assume-role-policy"
  group = aws_iam_group.security_auditors.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sts:AssumeRole"]
      Resource = [aws_iam_role.security_auditors_access.arn]
    }]
  })
}

#
# View only: list resources and basic metadata across all services, no content access
#
resource "aws_iam_role" "view_only_access" {
  name               = "CompliantFrameworkViewOnlyAccessRole"
  path               = "/"
  assume_role_policy = local.same_account_trust
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "view_only_access" {
  role       = aws_iam_role.view_only_access.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_group" "view_only" {
  name = "CompliantFrameworkViewOnlyGroup"
}

resource "aws_iam_group_policy" "view_only" {
  name  = "assume-role-policy"
  group = aws_iam_group.view_only.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sts:AssumeRole"]
      Resource = [aws_iam_role.view_only_access.arn]
    }]
  })
}
