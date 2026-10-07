# Compliant Framework – Terraform

This directory is the Terraform implementation of the Compliant Framework for
Federal and DoD Workloads in AWS GovCloud (US). It replaces the CDK bootstrap
stack, the CodeBuild/CodePipeline orchestration and the CloudFormation
templates/StackSets under `source/`, and deploys the same resources with the same
physical names. The legacy implementation is kept under `source/` until
existing deployments have been migrated (see [Migrating an existing
deployment](#migrating-an-existing-deployment)).

## Layout

```
terraform/
├── config/framework.example.yaml   single configuration file (replaces config.json + stack parameters)
├── live/                           root configurations, applied in order
│   ├── 00-tfstate                  S3 state bucket + KMS key (local state)
│   ├── 01-commercial-accounts      commercial payer: GovCloud account creation, Account Vending Machine
│   ├── 02-govcloud-organization    GovCloud org, OUs, invitations, RAM / Service Catalog org access
│   ├── 03-core                     Logging + Central accounts (logging-init / central-init)
│   ├── 04-environment              one state per environment: Transit + Management Services accounts
│   └── 05-account-baseline         one state per member account (replaces the StackSets)
├── modules/                        one module per CloudFormation template (or template family)
└── scripts/
    ├── deploy.sh                   applies the layers in dependency order
    ├── validate.sh                 offline fmt/validate/mock-plan tests
    └── govcloud_org_membership.py  org invitation/handshake + OU placement (no native TF resource)
```

## What replaced what

| CloudFormation / CDK | Terraform |
| --- | --- |
| `source/lib/compliant-framework-stack.ts` (Step Functions: verify keys, init org, CreateGovCloudAccount, invite) | `live/01-commercial-accounts` (`aws_organizations_account` with `create_govcloud`) + `live/02-govcloud-organization` |
| `source/lib/account-vending-machine` | `modules/account-vending-machine` (optional, in `01-commercial-accounts`) |
| `buildspec.yml`, `create_config.py`, CodeCommit repos, core/environment CodePipelines, cross-account CDK bootstrap stacks | `scripts/deploy.sh` + S3 backend; providers assume `CompliantFrameworkAccountAccessRole` |
| `initialize_organizational_units`, `invite_accounts`, `initialize_organization` Lambdas | `live/02-govcloud-organization` |
| `logging-init.yml`, `central-init.yml` (+ nested `logging-assets`, `security-*`) | `live/03-core` with `modules/{logging-assets,cloudtrail,config,security-hub,guardduty,iam-groups}` |
| `management-services-logging.yml`, `management-services-init.yml` (+ nested VPCs, assets bucket, Service Catalog) | `live/04-environment` with `modules/{management-services-logging,management-services-assets-bucket,management-services-vpc,directory-vpc,external-access-vpc,service-catalog-portfolio}` |
| `transit-init.yml` (+ nested TGW, firewall/DMZ/inspection VPCs, VPN) | `live/04-environment` with `modules/{transit-gateway,transit-firewall-vpc,transit-dmz-vpc,transit-inspection-vpc,transit-vpn-attachment}` |
| `transit-gateway-route-tables.yml` (+ `virtual-firewall/*`, `vpc-firewall/*`) | `modules/transit-gateway-route-tables` |
| `transit-attach-tenant.yml` (plugins) | `modules/transit-attach-tenant`, driven by `environments.<env>.tenants` |
| StackSets `security-baseline`, `backup-services`, `federation` | `live/05-account-baseline` with `modules/{security-baseline,backup-services,federation}` |
| `security_hub_invite_members` Lambda | `aws_securityhub_member` / `aws_securityhub_invite_accepter` in `03-core` and `05-account-baseline` |
| Values passed through SSM parameters / stack outputs between stacks | Module outputs wired directly; the SSM parameters other systems read are still written |

Two things deliberately stay CloudFormation, because AWS Service Catalog
`CLOUD_FORMATION_TEMPLATE` products are CloudFormation by definition: the
Account Vending Machine product and the Tenant Two-Tier VPC product. Terraform
manages the portfolios, products, Lambdas and the S3 upload of those templates.

## Prerequisites

- Terraform >= 1.10 (S3 native state locking), Python 3 with `boto3` and `PyYAML`
  (used by `scripts/`).
- Credentials for the **commercial** organization management (payer) account
  that is enabled for AWS GovCloud (US) (layer 01 only).
- Credentials for the **GovCloud central** account, i.e. the GovCloud account
  paired with the payer (all other layers). Terraform reaches every other
  account by assuming `account_access_role_name`.

## Deployment

1. `cp config/framework.example.yaml config/framework.yaml` and edit it.
2. Commercial accounts (commercial credentials, any backend reachable with them):
   ```
   terraform -chdir=live/01-commercial-accounts init -backend-config=../../backend-commercial.hcl -backend-config=key=compliant-framework/commercial-accounts.tfstate
   terraform -chdir=live/01-commercial-accounts apply
   ```
   Copy the `govcloud_accounts[*].govcloud_id` outputs into `central`,
   `logging` and `environments.*` in `config/framework.yaml`.
3. State backend (GovCloud credentials):
   ```
   terraform -chdir=live/00-tfstate init && terraform -chdir=live/00-tfstate apply
   terraform -chdir=live/00-tfstate output -raw backend_hcl > backend.hcl
   ```
4. Everything else, in order (organization, core, each environment, each
   member account baseline):
   ```
   scripts/deploy.sh all            # or: organization | core | environment prod | baselines [prod]
   TF_ACTION=plan scripts/deploy.sh environment prod
   ```

If the GovCloud organization already exists, import it before the first apply
of `02-govcloud-organization`
(`terraform import aws_organizations_organization.this o-xxxxxxxxxx`) and list
its already enabled service principals in `aws_service_access_principals`.

Additional environments (alpha, beta, ...) and tenant (Mission App / plugin)
accounts are added under `environments` (accounts can be created with
`commercial.govcloud_accounts` or the Account Vending Machine). Plugin workloads
themselves are no longer CloudFormation pipeline actions; write them as
Terraform and attach their VPCs through `tenants[*].transit_gateway_attachment_id`.

## Testing

`scripts/validate.sh` runs `terraform fmt -check`, `validate` for every module
and layer, and `terraform test` plans against mocked AWS providers
(`live/*/tests`, using the example config and a VPC-firewall variant). No AWS
credentials are needed.

## Migrating an existing deployment

Resources keep the CloudFormation physical names, so an existing deployment can
be adopted without rebuilding networks or log buckets:

1. Deploy nothing new; for each layer write `import` blocks (or run
   `terraform import`) for the resources of the matching stack, then run
   `terraform plan` until it shows no destructive changes. Names that
   CloudFormation generated (e.g. CloudTrail trail/log group, Config recorder,
   flow-log groups/roles, metric filters, Lambda roles) are module variables –
   set them to the existing names. Each module README lists these under
   "Differences from CloudFormation".
2. Set `DeletionPolicy: Retain` on the old stacks (or delete them with
   "retain resources"), then delete the stacks, StackSets, pipelines and the
   `CompliantFramework` state machine.

## Known differences

Behavioural differences are documented per module (`modules/*/README.md`).
Highlights:

- Lambda runtimes moved from python3.7/3.8 to python3.12; custom resources that
  had a native equivalent (IAM password policy) are now native resources.
- The commercial-side SNS notifications, state machine and anonymous metrics
  (SolutionHelper) are gone; Terraform reports progress and errors directly.
- The framework is deployed to `primary_region` per environment
  (`environments.<env>.region`); the CloudFormation multi-region scaffolding
  (`deployToRegions`) was only ever used with `us-gov-west-1`.
- The environment assets bucket is always created (it backs the Service
  Catalog product templates), not only with the Directory VPC.
- Tenant Transit Gateway attachments are associated from the Transit account
  (the TGW owner); the old plugin pipeline action deployed them in the plugin
  account.
- Source issues kept intentionally for parity and flagged in module READMEs:
  CIS 1.1 alarm watches `RootAccountUsage` while the filter emits `RootAccount`;
  the Security Hub alarm topic's CMK policy does not grant CloudWatch; the
  Two-Tier VPC product's `ServiceToken` ARN has no account id; the federation
  roles expect an existing IAM SAML provider.
