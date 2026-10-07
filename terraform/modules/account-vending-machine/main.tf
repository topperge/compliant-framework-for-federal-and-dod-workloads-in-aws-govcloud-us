# Converted from CDK construct source/lib/account-vending-machine/account-vending-machine-construct.ts
# (synthesized CFN: source/test/__snapshots__/account-vending-machine-construct.test.ts.snap).
# Deployed in the COMMERCIAL AWS Organizations management (payer) account.

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  # Physical function names are fixed: the product template builds the custom resource ServiceTokens from them.
  functions = {
    create_govcloud_account = {
      function_name = "CompliantFramework-AvmCreateGovCloudAccount"
      source_dir    = "avm_create_govcloud_account"
      reads_ssm     = false
    }
    invite_govcloud_account = {
      function_name = "CompliantFramework-AvmInviteGovCloudAccount"
      source_dir    = "avm_invite_govcloud_account"
      reads_ssm     = true
    }
    get_ou = {
      function_name = "CompliantFramework-AvmGetOu"
      source_dir    = "avm_get_ou"
      reads_ssm     = true
    }
    move_account = {
      function_name = "CompliantFramework-AvmMoveAccount"
      source_dir    = "avm_move_account"
      reads_ssm     = true
    }
  }

  ssm_parameter_arns = [
    for name in [var.govcloud_access_key_id_parameter_name, var.govcloud_secret_access_key_parameter_name] :
    "arn:${local.partition}:ssm:${local.region}:${local.account_id}:parameter/${trimprefix(name, "/")}"
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# Lambda functions (custom resource handlers used by the Service Catalog product template)
# ---------------------------------------------------------------------------------------------------------------------
data "archive_file" "avm" {
  for_each = local.functions

  type        = "zip"
  source_dir  = "${path.module}/lambda/${each.value.source_dir}"
  output_path = "${path.module}/.build/${each.value.source_dir}.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "avm" {
  for_each = local.functions

  name               = "${each.value.function_name}-Role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

# CDK attached AWSLambdaBasicExecutionRole to every function role by default.
resource "aws_iam_role_policy_attachment" "avm_basic_execution" {
  for_each = local.functions

  role       = aws_iam_role.avm[each.key].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "avm" {
  for_each = local.functions

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:${each.value.function_name}"]
  }

  # cfn_nag W12: Organizations account-creation actions require use of * resource
  dynamic "statement" {
    for_each = each.key == "create_govcloud_account" ? [1] : []
    content {
      actions = [
        "organizations:CreateGovCloudAccount",
        "organizations:ListAccounts",
        "organizations:DescribeCreateAccountStatus",
      ]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = each.value.reads_ssm ? [1] : []
    content {
      actions   = ["ssm:GetParameter"]
      resources = local.ssm_parameter_arns
    }
  }

  dynamic "statement" {
    for_each = each.value.reads_ssm && var.ssm_kms_key_arn != null ? [1] : []
    content {
      actions   = ["kms:Decrypt"]
      resources = [var.ssm_kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "avm" {
  for_each = local.functions

  name   = "${each.value.function_name}-DefaultPolicy"
  role   = aws_iam_role.avm[each.key].id
  policy = data.aws_iam_policy_document.avm[each.key].json
}

resource "aws_lambda_function" "avm" {
  for_each = local.functions

  function_name    = each.value.function_name
  role             = aws_iam_role.avm[each.key].arn
  handler          = "index.lambda_handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  filename         = data.archive_file.avm[each.key].output_path
  source_code_hash = data.archive_file.avm[each.key].output_base64sha256

  dynamic "environment" {
    for_each = each.value.reads_ssm ? [1] : []
    content {
      variables = {
        GOVCLOUD_ACCESS_KEY_ID_PARAMETER     = var.govcloud_access_key_id_parameter_name
        GOVCLOUD_SECRET_ACCESS_KEY_PARAMETER = var.govcloud_secret_access_key_parameter_name
        GOVCLOUD_REGION                      = var.govcloud_region
      }
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.avm,
    aws_iam_role_policy_attachment.avm_basic_execution,
  ]
}
