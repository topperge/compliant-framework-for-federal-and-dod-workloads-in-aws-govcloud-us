# Compliant Framework – Terraform

This directory is the Terraform implementation of the Compliant Framework for
Federal and DoD Workloads in AWS GovCloud (US). It replaces the CDK bootstrap
stack, the CodeBuild/CodePipeline orchestration and the CloudFormation
templates/StackSets under `source/`, and deploys the same resources with the same
physical names. It can target either **AWS GovCloud (US)** or the
**commercial AWS partition** (see [Choosing a target partition](#choosing-a-target-partition)).
The legacy implementation is kept under `source/` until
existing deployments have been migrated (see [Migrating an existing
deployment](#migrating-an-existing-deployment)).

## Layout

```
terraform/
├── config/
│   ├── framework.example.yaml             configuration for AWS GovCloud (US) (replaces config.json + stack parameters)
│   └── framework.commercial.example.yaml  configuration for commercial AWS regions
├── live/                           root configurations, applied in order
│   ├── 00-tfstate                  S3 state bucket + KMS key (local state)
│   ├── 01-accounts                 commercial payer: account creation (GovCloud or commercial), Account Vending Machine
│   ├── 02-organization             target-partition org, OUs, invitations, RAM / Service Catalog org access
│   ├── 03-core                     Logging + Central accounts (logging-init / central-init)
│   ├── 04-environment              one state per environment: Transit + Management Services accounts
│   └── 05-account-baseline         one state per member account (replaces the StackSets)
├── modules/                        one module per CloudFormation template (or template family)
└── scripts/
    ├── deploy.sh                   applies the layers in dependency order
    ├── validate.sh                 offline fmt/validate/mock-plan tests
    └── org_membership.py           org invitation/handshake + OU placement (no native TF resource)
```

## What replaced what

| CloudFormation / CDK | Terraform |
| --- | --- |
| `source/lib/compliant-framework-stack.ts` (Step Functions: verify keys, init org, CreateGovCloudAccount, invite) | `live/01-accounts` (`aws_organizations_account` with `create_govcloud`) + `live/02-organization` |
| `source/lib/account-vending-machine` | `modules/account-vending-machine` (optional, in `01-accounts`) |
| `buildspec.yml`, `create_config.py`, CodeCommit repos, core/environment CodePipelines, cross-account CDK bootstrap stacks | `scripts/deploy.sh` + S3 backend; providers assume `CompliantFrameworkAccountAccessRole` |
| `initialize_organizational_units`, `invite_accounts`, `initialize_organization` Lambdas | `live/02-organization` |
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

## Choosing a target partition

The `partition` key in `config/framework.yaml` selects where the framework is
built. Every module derives the partition, region and account from the AWS
provider at plan time (`aws_partition`, `aws_region`, `aws_caller_identity`),
so the same code produces `arn:aws-us-gov:...` or `arn:aws:...` resources.

| | AWS GovCloud (US) | Commercial AWS |
| --- | --- | --- |
| `partition` | `aws-us-gov` | `aws` |
| `primary_region` / `environments.<env>.region` | `us-gov-west-1` (or `us-gov-east-1`) | any commercial region, e.g. `us-east-1` |
| Start from | `config/framework.example.yaml` | `config/framework.commercial.example.yaml` |
| `01-accounts` | commercial payer credentials; `CreateGovCloudAccount` creates a commercial twin (in OU `govcloud-accounts`) **and** a GovCloud account per entry | commercial payer credentials; `CreateAccount` creates the account directly in the organization |
| Central account (layers 00, 02-05) | the GovCloud account paired with the payer | the commercial payer (organization management account) itself |
| `02-organization` | GovCloud organization; accounts are **invited** (handshake accepted through `account_access_role_name`) and moved into OUs | the existing commercial organization; accounts are already members and are only moved into OUs |
| Account ids in the config | `accounts[*].account_id` output of `01-accounts` (= GovCloud ids) | `accounts[*].account_id` output of `01-accounts` (= commercial ids) |
| State backends | two: one in the commercial payer for `01-accounts` (`backend-commercial.hcl`), one in GovCloud for everything else (`backend.hcl`) | one (`backend.hcl`) for every layer |
| Account Vending Machine | optional (`commercial.account_vending_machine.enabled`) | not available (it creates GovCloud accounts); the plan fails if enabled |
| Region-gated Config rules (`security-baseline`) | the 9 rules unsupported in GovCloud are skipped (as in CloudFormation) | all rules are deployed |
| Organization OU names | `environment-usgw1-<env>` | derived from the region, e.g. `environment-use1-<env>` |

Every layer except `01-accounts` checks that its credentials belong to the
configured partition and fails the plan otherwise; `01-accounts` checks that it
runs with commercial credentials. Region-specific service availability still
applies: confirm that every service the framework uses (Transit Gateway, AWS
Backup, Security Hub, GuardDuty, Config, Service Catalog, VPC endpoints for
SSM/EFS) is available in the region you choose.

## Prerequisites

- Terraform >= 1.10 (S3 native state locking), Python 3 with `boto3` and `PyYAML`
  (used by `scripts/`).
- Credentials for the **commercial** organization management (payer) account
  (layer 01; for GovCloud it must be enabled for AWS GovCloud (US)).
- Credentials for the **central** account of the target partition (all other
  layers): the GovCloud account paired with the payer for `aws-us-gov`, or the
  payer itself for `aws`. Terraform reaches every other account by assuming
  `account_access_role_name`.

Credentials come from the standard AWS environment (`AWS_PROFILE`,
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, SSO, ...); the layers do not hard
code profiles. For GovCloud you typically keep two profiles and switch between
them, e.g. `AWS_PROFILE=payer` for step 2 and `AWS_PROFILE=govcloud-central`
afterwards.

## Deployment

### AWS GovCloud (US)

1. `cp config/framework.example.yaml config/framework.yaml` and edit it.
2. Accounts (commercial payer credentials, `backend-commercial.hcl` pointing at
   an S3 bucket in the commercial partition, or a local backend):
   ```
   AWS_PROFILE=payer scripts/deploy.sh accounts
   ```
   Copy the `accounts[*].account_id` outputs into `central`, `logging` and
   `environments.*` in `config/framework.yaml`.
3. State backend (GovCloud central credentials):
   ```
   export AWS_PROFILE=govcloud-central
   terraform -chdir=live/00-tfstate init && terraform -chdir=live/00-tfstate apply
   terraform -chdir=live/00-tfstate output -raw backend_hcl > backend.hcl
   ```
4. Everything else, in order (organization, core, each environment, each
   member account baseline):
   ```
   scripts/deploy.sh all            # or: organization | core | environment prod | baselines [prod]
   TF_ACTION=plan scripts/deploy.sh environment prod
   ```

### Commercial AWS

1. `cp config/framework.commercial.example.yaml config/framework.yaml`, set
   `primary_region`/`environments.<env>.region` and the account details.
   `central.account_id` is the organization management account.
2. State backend (management account credentials):
   ```
   export AWS_PROFILE=payer
   terraform -chdir=live/00-tfstate init && terraform -chdir=live/00-tfstate apply
   terraform -chdir=live/00-tfstate output -raw backend_hcl > backend.hcl
   ```
3. Accounts (same credentials and backend):
   ```
   scripts/deploy.sh accounts
   ```
   Copy the `accounts[*].account_id` outputs into `logging` and
   `environments.*`. Existing accounts can be used instead; just list their ids
   and leave them out of `commercial.accounts`.
4. Import the existing organization (see below), then everything else:
   ```
   scripts/deploy.sh all
   ```

### Common notes

If the organization already exists (always for commercial; possibly for
GovCloud), import it before the first apply of `02-organization`
(`terraform import aws_organizations_organization.this o-xxxxxxxxxx`) and list
its already enabled service principals in `aws_service_access_principals`,
otherwise Terraform disables them.

Additional environments (alpha, beta, ...) and tenant (Mission App / plugin)
accounts are added under `environments` (accounts can be created with
`commercial.accounts` or the Account Vending Machine). Plugin workloads
themselves are no longer CloudFormation pipeline actions; write them as
Terraform and attach their VPCs through `tenants[*].transit_gateway_attachment_id`.

## Testing

`scripts/validate.sh` runs `terraform fmt -check`, `validate` for every module
and layer, and `terraform test` plans against mocked AWS providers
(`live/*/tests/{govcloud,commercial}.tftest.hcl`), once per partition with
the matching example config, plus a VPC-firewall variant and negative tests
(partition mismatch, foreign account, AVM in commercial). No AWS credentials are
needed.

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
- Commercial-partition deployments are new (the CloudFormation version only
  supported GovCloud).
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
