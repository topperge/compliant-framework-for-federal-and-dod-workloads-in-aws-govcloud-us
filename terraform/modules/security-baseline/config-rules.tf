##################################################################################
#
#   Conformance Pack:
#     Operational Best Practices for CMMC Level 5
#
#   AWS managed Config rules. Map key = ConfigRuleName; "condition" names the CFN
#   condition that gated the rule (rule is skipped when it evaluates to false).
#
##################################################################################

locals {
  config_rules = {
    "account-part-of-organizations" = {
      source_identifier = "ACCOUNT_PART_OF_ORGANIZATIONS"
      # CFN logical id: AccountPartOfOrganizations
    }
    "alb-http-drop-invalid-header-enabled" = {
      source_identifier = "ALB_HTTP_DROP_INVALID_HEADER_ENABLED"
      resource_types    = ["AWS::ElasticLoadBalancingV2::LoadBalancer"]
      # CFN logical id: AlbHttpDropInvalidHeaderEnabled
    }
    "alb-waf-enabled" = {
      source_identifier = "ALB_WAF_ENABLED"
      resource_types    = ["AWS::ElasticLoadBalancingV2::LoadBalancer"]
      condition         = "cIsNotGovCloud" # CFN logical id: AlbWafEnabled
    }
    "api-gw-cache-enabled-and-encrypted" = {
      source_identifier = "API_GW_CACHE_ENABLED_AND_ENCRYPTED"
      resource_types    = ["AWS::ApiGateway::Stage"]
      # CFN logical id: ApiGwCacheEnabledAndEncrypted
    }
    "api-gw-execution-logging-enabled" = {
      source_identifier = "API_GW_EXECUTION_LOGGING_ENABLED"
      resource_types    = ["AWS::ApiGateway::Stage", "AWS::ApiGatewayV2::Stage"]
      # CFN logical id: ApiGwExecutionLoggingEnabled
    }
    "cloudtrail-enabled" = {
      source_identifier = "CLOUD_TRAIL_ENABLED"
      # CFN logical id: CloudTrailEnabled
    }
    "cloudtrail-s3-dataevents-enabled" = {
      source_identifier = "CLOUDTRAIL_S3_DATAEVENTS_ENABLED"
      # CFN logical id: CloudtrailS3DataeventsEnabled
    }
    "cloudtrail-security-trail-enabled" = {
      source_identifier = "CLOUDTRAIL_SECURITY_TRAIL_ENABLED"
      # CFN logical id: CloudtrailSecurityTrailEnabled
    }
    "cloudwatch-alarm-action-check" = {
      source_identifier = "CLOUDWATCH_ALARM_ACTION_CHECK"
      input_parameters  = { alarmActionRequired = "TRUE", insufficientDataActionRequired = "TRUE", okActionRequired = "FALSE" }
      resource_types    = ["AWS::CloudWatch::Alarm"]
      # CFN logical id: CloudwatchAlarmActionCheck
    }
    "cloudwatch-log-group-encrypted" = {
      source_identifier = "CLOUDWATCH_LOG_GROUP_ENCRYPTED"
      # CFN logical id: CloudwatchLogGroupEncrypted
    }
    "codebuild-project-envvar-awscred-check" = {
      source_identifier = "CODEBUILD_PROJECT_ENVVAR_AWSCRED_CHECK"
      resource_types    = ["AWS::CodeBuild::Project"]
      condition         = "cIsNotGovCloudEast1" # CFN logical id: CodebuildProjectEnvvarAwscredCheck
    }
    "codebuild-project-source-repo-url-check" = {
      source_identifier = "CODEBUILD_PROJECT_SOURCE_REPO_URL_CHECK"
      resource_types    = ["AWS::CodeBuild::Project"]
      condition         = "cIsNotGovCloudEast1" # CFN logical id: CodebuildProjectSourceRepoUrlCheck
    }
    "cw-loggroup-retention-period-check" = {
      source_identifier = "CW_LOGGROUP_RETENTION_PERIOD_CHECK"
      # CFN logical id: CwLoggroupRetentionPeriodCheck
    }
    "db-instance-backup-enabled" = {
      source_identifier = "DB_INSTANCE_BACKUP_ENABLED"
      resource_types    = ["AWS::RDS::DBInstance"]
      # CFN logical id: DbInstanceBackupEnabled
    }
    "dynamodb-autoscaling-enabled" = {
      source_identifier = "DYNAMODB_AUTOSCALING_ENABLED"
      resource_types    = ["AWS::DynamoDB::Table"]
      condition         = "cIsNotGovCloud" # CFN logical id: DynamodbAutoscalingEnabled
    }
    "dynamodb-in-backup-plan" = {
      source_identifier = "DYNAMODB_IN_BACKUP_PLAN"
      condition         = "cIsNotGovCloud" # CFN logical id: DynamodbInBackupPlan
    }
    "dynamodb-pitr-enabled" = {
      source_identifier = "DYNAMODB_PITR_ENABLED"
      resource_types    = ["AWS::DynamoDB::Table"]
      # CFN logical id: DynamodbPitrEnabled
    }
    "ebs-in-backup-plan" = {
      source_identifier = "EBS_IN_BACKUP_PLAN"
      condition         = "cIsNotGovCloud" # CFN logical id: EbsInBackupPlan
    }
    "ebs-optimized-instance" = {
      source_identifier = "EBS_OPTIMIZED_INSTANCE"
      resource_types    = ["AWS::EC2::Instance"]
      # CFN logical id: EbsOptimizedInstance
    }
    "ec2-instance-detailed-monitoring-enabled" = {
      source_identifier = "EC2_INSTANCE_DETAILED_MONITORING_ENABLED"
      resource_types    = ["AWS::EC2::Instance"]
      # CFN logical id: Ec2InstanceDetailedMonitoringEnabled
    }
    "ec2-instance-no-public-ip" = {
      source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
      resource_types    = ["AWS::EC2::Instance"]
      # CFN logical id: Ec2InstanceNoPublicIp
    }
    "ec2-security-group-attached-to-eni" = {
      source_identifier = "EC2_SECURITY_GROUP_ATTACHED_TO_ENI"
      resource_types    = ["AWS::EC2::SecurityGroup"]
      # CFN logical id: Ec2SecurityGroupAttachedToEni
    }
    "ec2-volume-inuse-check" = {
      source_identifier = "EC2_VOLUME_INUSE_CHECK"
      input_parameters  = { deleteOnTermination = "TRUE" }
      resource_types    = ["AWS::EC2::Volume"]
      # CFN logical id: Ec2VolumeInuseCheck
    }
    "efs-in-backup-plan" = {
      source_identifier = "EFS_IN_BACKUP_PLAN"
      condition         = "cIsNotGovCloud" # CFN logical id: EfsInBackupPlan
    }
    "eip-attached" = {
      source_identifier = "EIP_ATTACHED"
      resource_types    = ["AWS::EC2::EIP"]
      # CFN logical id: EipAttached
    }
    "elasticache-redis-cluster-automatic-backup-check" = {
      source_identifier = "ELASTICACHE_REDIS_CLUSTER_AUTOMATIC_BACKUP_CHECK"
      # CFN logical id: ElasticacheRedisClusterAutomaticBackupCheck
    }
    "elasticsearch-in-vpc-only" = {
      source_identifier = "ELASTICSEARCH_IN_VPC_ONLY"
      # CFN logical id: ElasticsearchInVpcOnly
    }
    "elasticsearch-node-to-node-encryption-check" = {
      source_identifier = "ELASTICSEARCH_NODE_TO_NODE_ENCRYPTION_CHECK"
      resource_types    = ["AWS::Elasticsearch::Domain"]
      # CFN logical id: ElasticsearchNodeToNodeEncryptionCheck
    }
    "elb-acm-certificate-required" = {
      source_identifier = "ELB_ACM_CERTIFICATE_REQUIRED"
      resource_types    = ["AWS::ElasticLoadBalancing::LoadBalancer"]
      condition         = "cIsNotGovCloudEast1" # CFN logical id: ElbAcmCertificateRequired
    }
    "elb-cross-zone-load-balancing-enabled" = {
      source_identifier = "ELB_CROSS_ZONE_LOAD_BALANCING_ENABLED"
      resource_types    = ["AWS::ElasticLoadBalancing::LoadBalancer"]
      # CFN logical id: ElbCrossZoneLoadBalancingEnabled
    }
    "elb-deletion-protection-enabled" = {
      source_identifier = "ELB_DELETION_PROTECTION_ENABLED"
      resource_types    = ["AWS::ElasticLoadBalancingV2::LoadBalancer"]
      # CFN logical id: ElbDeletionProtectionEnabled
    }
    "elb-logging-enabled" = {
      source_identifier = "ELB_LOGGING_ENABLED"
      resource_types    = ["AWS::ElasticLoadBalancing::LoadBalancer", "AWS::ElasticLoadBalancingV2::LoadBalancer"]
      # CFN logical id: ElbLoggingEnabled
    }
    "elb-tls-https-listeners-only" = {
      source_identifier = "ELB_TLS_HTTPS_LISTENERS_ONLY"
      resource_types    = ["AWS::ElasticLoadBalancing::LoadBalancer"]
      # CFN logical id: ElbTlsHttpsListenersOnly
    }
    "emr-kerberos-enabled" = {
      source_identifier = "EMR_KERBEROS_ENABLED"
      # CFN logical id: EmrKerberosEnabled
    }
    "guardduty-enabled-centralized" = {
      source_identifier = "GUARDDUTY_ENABLED_CENTRALIZED"
      condition         = "cIsNotGovCloudEast1" # CFN logical id: GuarddutyEnabledCentralized
    }
    "guardduty-non-archived-findings" = {
      source_identifier = "GUARDDUTY_NON_ARCHIVED_FINDINGS"
      input_parameters  = { daysHighSev = "1", daysLowSev = "30", daysMediumSev = "7" }
      condition         = "cIsNotGovCloudEast1" # CFN logical id: GuarddutyNonArchivedFindings
    }
    "iam-group-has-users-check" = {
      source_identifier = "IAM_GROUP_HAS_USERS_CHECK"
      resource_types    = ["AWS::IAM::Group"]
      # CFN logical id: IamGroupHasUsersCheck
    }
    "iam-no-inline-policy-check" = {
      source_identifier = "IAM_NO_INLINE_POLICY_CHECK"
      resource_types    = ["AWS::IAM::User", "AWS::IAM::Role", "AWS::IAM::Group"]
      # CFN logical id: IamNoInlinePolicyCheck
    }
    "iam-user-group-membership-check" = {
      source_identifier = "IAM_USER_GROUP_MEMBERSHIP_CHECK"
      resource_types    = ["AWS::IAM::User"]
      # CFN logical id: IamUserGroupMembershipCheck
    }
    "iam-user-mfa-enabled" = {
      source_identifier = "IAM_USER_MFA_ENABLED"
      # CFN logical id: IamUserMfaEnabled
    }
    "ec2-instances-in-vpc" = {
      source_identifier = "INSTANCES_IN_VPC"
      resource_types    = ["AWS::EC2::Instance"]
      # CFN logical id: InstancesInVpc
    }
    "internet-gateway-authorized-vpc-only" = {
      source_identifier = "INTERNET_GATEWAY_AUTHORIZED_VPC_ONLY"
      resource_types    = ["AWS::EC2::InternetGateway"]
      # CFN logical id: InternetGatewayAuthorizedVpcOnly
    }
    "kms-cmk-not-scheduled-for-deletion" = {
      source_identifier = "KMS_CMK_NOT_SCHEDULED_FOR_DELETION"
      resource_types    = ["AWS::KMS::Key"]
      # CFN logical id: KmsCmkNotScheduledForDeletion
    }
    "lambda-dlq-check" = {
      source_identifier = "LAMBDA_DLQ_CHECK"
      resource_types    = ["AWS::Lambda::Function"]
      # CFN logical id: LambdaDlqCheck
    }
    "lambda-inside-vpc" = {
      source_identifier = "LAMBDA_INSIDE_VPC"
      resource_types    = ["AWS::Lambda::Function"]
      # CFN logical id: LambdaInsideVpc
    }
    "rds-in-backup-plan" = {
      source_identifier = "RDS_IN_BACKUP_PLAN"
      condition         = "cIsNotGovCloud" # CFN logical id: RdsInBackupPlan
    }
    "rds-logging-enabled" = {
      source_identifier = "RDS_LOGGING_ENABLED"
      resource_types    = ["AWS::RDS::DBInstance"]
      # CFN logical id: RdsLoggingEnabled
    }
    "redshift-cluster-configuration-check" = {
      source_identifier = "REDSHIFT_CLUSTER_CONFIGURATION_CHECK"
      input_parameters  = { clusterDbEncrypted = "TRUE", loggingEnabled = "TRUE" }
      resource_types    = ["AWS::Redshift::Cluster"]
      # CFN logical id: RedshiftClusterConfigurationCheck
    }
    "redshift-cluster-public-access-check" = {
      source_identifier = "REDSHIFT_CLUSTER_PUBLIC_ACCESS_CHECK"
      resource_types    = ["AWS::Redshift::Cluster"]
      # CFN logical id: RedshiftClusterPublicAccessCheck
    }
    "redshift-require-tls-ssl" = {
      source_identifier = "REDSHIFT_REQUIRE_TLS_SSL"
      resource_types    = ["AWS::Redshift::Cluster"]
      # CFN logical id: RedshiftRequireTlsSsl
    }
    "root-account-hardware-mfa-enabled" = {
      source_identifier = "ROOT_ACCOUNT_HARDWARE_MFA_ENABLED"
      condition         = "cIsNotGovCloud" # CFN logical id: RootAccountHardwareMfaEnabled
    }
    "root-account-mfa-enabled" = {
      source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
      condition         = "cIsNotGovCloud" # CFN logical id: RootAccountMfaEnabled
    }
    "s3-bucket-default-lock-enabled" = {
      source_identifier = "S3_BUCKET_DEFAULT_LOCK_ENABLED"
      resource_types    = ["AWS::S3::Bucket"]
      # CFN logical id: S3BucketDefaultLockEnabled
    }
    "s3-bucket-policy-grantee-check" = {
      source_identifier = "S3_BUCKET_POLICY_GRANTEE_CHECK"
      resource_types    = ["AWS::S3::Bucket"]
      # CFN logical id: S3BucketPolicyGranteeCheck
    }
    "s3-bucket-replication-enabled" = {
      source_identifier = "S3_BUCKET_REPLICATION_ENABLED"
      resource_types    = ["AWS::S3::Bucket"]
      # CFN logical id: S3BucketReplicationEnabled
    }
    "s3-bucket-versioning-enabled" = {
      source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
      resource_types    = ["AWS::S3::Bucket"]
      # CFN logical id: S3BucketVersioningEnabled
    }
    "sagemaker-endpoint-configuration-kms-key-configured" = {
      source_identifier = "SAGEMAKER_ENDPOINT_CONFIGURATION_KMS_KEY_CONFIGURED"
      condition         = "cIsNotGovCloudEast1" # CFN logical id: SagemakerEndpointConfigurationKmsKeyConfigured
    }
    "sagemaker-notebook-instance-kms-key-configured" = {
      source_identifier = "SAGEMAKER_NOTEBOOK_INSTANCE_KMS_KEY_CONFIGURED"
      condition         = "cIsNotGovCloudEast1" # CFN logical id: SagemakerNotebookInstanceKmsKeyConfigured
    }
    "securityhub-enabled" = {
      source_identifier = "SECURITYHUB_ENABLED"
      # CFN logical id: SecurityhubEnabled
    }
    "sns-encrypted-kms" = {
      source_identifier = "SNS_ENCRYPTED_KMS"
      resource_types    = ["AWS::SNS::Topic"]
      # CFN logical id: SnsEncryptedKms
    }
    "vpc-sg-open-only-to-authorized-ports" = {
      source_identifier = "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS"
      input_parameters  = { authorizedTcpPorts = "443" }
      resource_types    = ["AWS::EC2::SecurityGroup"]
      # CFN logical id: VpcSgOpenOnlyToAuthorizedPorts
    }
    "vpc-vpn-2-tunnels-up" = {
      source_identifier = "VPC_VPN_2_TUNNELS_UP"
      resource_types    = ["AWS::EC2::VPNConnection"]
      # CFN logical id: VpcVpn2TunnelsUp
    }
    "wafv2-logging-enabled" = {
      source_identifier = "WAFV2_LOGGING_ENABLED"
      condition         = "cIsNotGovCloud" # CFN logical id: Wafv2LoggingEnabled
    }
  }

  enabled_config_rules = {
    for name, rule in local.config_rules : name => rule
    if lookup(local.conditions, try(rule.condition, ""), true)
  }
}

resource "aws_config_config_rule" "conformance_pack" {
  for_each = local.enabled_config_rules

  name             = each.key
  input_parameters = try(jsonencode(each.value.input_parameters), null)

  dynamic "scope" {
    for_each = can(each.value.resource_types) ? [each.value.resource_types] : []
    content {
      compliance_resource_types = scope.value
    }
  }

  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  tags = var.tags

  depends_on = [
    aws_config_delivery_channel.config_delivery_channel,
    aws_config_configuration_recorder.config_configuration_recorder,
  ]
}
