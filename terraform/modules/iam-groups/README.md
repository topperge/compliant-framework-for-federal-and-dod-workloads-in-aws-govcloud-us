# iam-groups

Non-federated IAM groups (`CompliantFrameworkAdministratorsGroup`, `CompliantFrameworkSecurityAuditorsGroup`,
`CompliantFrameworkViewOnlyGroup`), each with an inline `assume-role-policy` allowing it to assume the matching
same-account role (`CompliantFramework{Administrators,SecurityAuditors,ViewOnly}AccessRole` with AdministratorAccess /
SecurityAudit / job-function/ViewOnlyAccess). Global IAM: deploy once per account (one region).

Source: `source/repositories/compliant-framework-central-core/templates/security/security-iam-groups.yml`

## Inputs
| Name | Type | Default |
|---|---|---|
| tags | map(string) | {} |

## Outputs
`administrators_access_role_arn`, `security_auditors_access_role_arn`, `view_only_access_role_arn`, `group_names`
(CFN template has no outputs).

## Differences from CloudFormation
- Trust principal written as `arn:<partition>:iam::<account>:root` (equivalent to CFN's bare account ID).
- In CFN the nested stack was deployed in every region of `deployToRegions`, which would fail on the global names
  in a second region; here instantiate it once per account.
