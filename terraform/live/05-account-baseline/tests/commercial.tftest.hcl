# Offline plan of this layer for commercial AWS against mocked AWS providers.
# Run: terraform init -backend=false && terraform test
mock_provider "aws" {
  mock_data "aws_partition" { defaults = { partition = "aws", dns_suffix = "amazonaws.com" } }
  mock_data "aws_region" { defaults = { region = "us-east-1", name = "us-east-1" } }
  mock_data "aws_caller_identity" { defaults = { account_id = "111111111111" } }
  mock_data "aws_availability_zones" { defaults = { names = ["us-east-1a", "us-east-1b", "us-east-1c"] } }
  mock_data "aws_organizations_organization" { defaults = { id = "o-abcdefghij", arn = "arn:aws:organizations::111111111111:organization/o-abcdefghij", roots = [{ id = "r-abcd", arn = "arn:aws:organizations::111111111111:root/o-abcdefghij/r-abcd", name = "Root", policy_types = [] }] } }
  mock_data "aws_ssm_parameter" { defaults = { value = "arn:aws:kms:us-east-1:222222222222:key/abc" } }
  mock_data "aws_iam_policy_document" { defaults = { json = "{}" } }
  mock_resource "aws_organizations_organization" { defaults = { id = "o-abcdefghij", arn = "arn:aws:organizations::111111111111:organization/o-abcdefghij", roots = [{ id = "r-abcd", arn = "arn:aws:organizations::111111111111:root/o-abcdefghij/r-abcd", name = "Root", policy_types = [] }] } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:222222222222:key/abc" } }
  mock_resource "aws_kms_alias" { defaults = { arn = "arn:aws:kms:us-east-1:222222222222:alias/abc" } }
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::222222222222:role/x" } }
  mock_resource "aws_iam_policy" { defaults = { arn = "arn:aws:iam::222222222222:policy/x" } }
  mock_resource "aws_s3_bucket" { defaults = { arn = "arn:aws:s3:::x" } }
  mock_resource "aws_sns_topic" { defaults = { arn = "arn:aws:sns:us-east-1:222222222222:x" } }
  mock_resource "aws_cloudwatch_log_group" { defaults = { arn = "arn:aws:logs:us-east-1:222222222222:log-group:x" } }
  mock_resource "aws_lambda_function" { defaults = { arn = "arn:aws:lambda:us-east-1:222222222222:function:x" } }
  mock_resource "aws_cloudtrail" { defaults = { arn = "arn:aws:cloudtrail:us-east-1:222222222222:trail/x" } }
  mock_resource "aws_ram_resource_share" { defaults = { arn = "arn:aws:ram:us-east-1:333333333333:resource-share/x" } }
  mock_resource "aws_ec2_transit_gateway" { defaults = { arn = "arn:aws:ec2:us-east-1:333333333333:transit-gateway/tgw-1" } }
  mock_resource "aws_subnet" { defaults = { arn = "arn:aws:ec2:us-east-1:333333333333:subnet/subnet-1" } }
  mock_resource "aws_backup_vault" { defaults = { arn = "arn:aws:backup:us-east-1:333333333333:backup-vault:x" } }
}

mock_provider "aws" {
  alias = "central"
  mock_data "aws_partition" { defaults = { partition = "aws", dns_suffix = "amazonaws.com" } }
  mock_data "aws_region" { defaults = { region = "us-east-1", name = "us-east-1" } }
  mock_data "aws_caller_identity" { defaults = { account_id = "111111111111" } }
  mock_data "aws_availability_zones" { defaults = { names = ["us-east-1a", "us-east-1b", "us-east-1c"] } }
  mock_data "aws_organizations_organization" { defaults = { id = "o-abcdefghij", arn = "arn:aws:organizations::111111111111:organization/o-abcdefghij", roots = [{ id = "r-abcd", arn = "arn:aws:organizations::111111111111:root/o-abcdefghij/r-abcd", name = "Root", policy_types = [] }] } }
  mock_data "aws_ssm_parameter" { defaults = { value = "arn:aws:kms:us-east-1:222222222222:key/abc" } }
  mock_data "aws_iam_policy_document" { defaults = { json = "{}" } }
  mock_resource "aws_organizations_organization" { defaults = { id = "o-abcdefghij", arn = "arn:aws:organizations::111111111111:organization/o-abcdefghij", roots = [{ id = "r-abcd", arn = "arn:aws:organizations::111111111111:root/o-abcdefghij/r-abcd", name = "Root", policy_types = [] }] } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:222222222222:key/abc" } }
  mock_resource "aws_kms_alias" { defaults = { arn = "arn:aws:kms:us-east-1:222222222222:alias/abc" } }
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::222222222222:role/x" } }
  mock_resource "aws_iam_policy" { defaults = { arn = "arn:aws:iam::222222222222:policy/x" } }
  mock_resource "aws_s3_bucket" { defaults = { arn = "arn:aws:s3:::x" } }
  mock_resource "aws_sns_topic" { defaults = { arn = "arn:aws:sns:us-east-1:222222222222:x" } }
  mock_resource "aws_cloudwatch_log_group" { defaults = { arn = "arn:aws:logs:us-east-1:222222222222:log-group:x" } }
  mock_resource "aws_lambda_function" { defaults = { arn = "arn:aws:lambda:us-east-1:222222222222:function:x" } }
  mock_resource "aws_cloudtrail" { defaults = { arn = "arn:aws:cloudtrail:us-east-1:222222222222:trail/x" } }
  mock_resource "aws_ram_resource_share" { defaults = { arn = "arn:aws:ram:us-east-1:333333333333:resource-share/x" } }
  mock_resource "aws_ec2_transit_gateway" { defaults = { arn = "arn:aws:ec2:us-east-1:333333333333:transit-gateway/tgw-1" } }
  mock_resource "aws_subnet" { defaults = { arn = "arn:aws:ec2:us-east-1:333333333333:subnet/subnet-1" } }
  mock_resource "aws_backup_vault" { defaults = { arn = "arn:aws:backup:us-east-1:333333333333:backup-vault:x" } }
}

run "plan_commercial" {
  command = plan

  # Rules gated by cIsNotGovCloud are only deployed outside GovCloud.
  assert {
    condition     = length(module.security_baseline.config_rule_names) == 63
    error_message = "Expected 63 Config rules, got ${length(module.security_baseline.config_rule_names)}."
  }

  variables {
    config_file = "../../config/framework.commercial.example.yaml"
    environment = "prod"
    account_id  = "333333333333"
  }
}

run "rejects_foreign_account" {
  command = plan

  variables {
    config_file = "../../config/framework.commercial.example.yaml"
    environment = "prod"
    account_id  = "999999999999"
  }

  expect_failures = [terraform_data.account_check]
}
