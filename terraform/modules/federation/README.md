# federation

SAML-federated IAM roles `<federation_name>-AdministratorAccess`, `-SystemAdministrator`, `-ViewOnlyAccess`
(6 h max session), trusting the SAML provider `saml-provider/<federation_name>` in the same account.

Source: `source/repositories/compliant-framework-security-baseline/templates/federation/federation.yml`
(formerly a StackSet to each environment OU plus plain stacks in the central and logging accounts; instantiate once
per account).

## Inputs

| Name | Type | Default |
|------|------|---------|
| federation_name | string | required (config `federation.name`, e.g. `KeyCloak`) |
| saml_endpoint | string | `https://signin.aws.amazon.com/saml` |
| tags | map(string) | `{}` |

## Outputs

`role_arns` (map keyed by `administrator_access_role`, `system_administrator_role`, `view_only_access_role`;
the CFN template had no Outputs).

## Differences from CloudFormation

- None functionally. The SAML provider is not created by this module (nor was it by the template); it must exist.
