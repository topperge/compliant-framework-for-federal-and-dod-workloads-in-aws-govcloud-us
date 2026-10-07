# CIS AWS Foundations Benchmark log metric filters, alarms and their notification topic.

resource "aws_kms_key" "security_hub_alarm_notification_topic_cmk" {
  description         = "Logging - S3 CMK"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy-1"
    Statement = [
      {
        Sid       = "Allow administration of the key"
        Effect    = "Allow"
        Principal = { AWS = ["arn:${local.partition}:iam::${local.account_id}:root"] }
        Action = [
          "kms:ListGrants",
          "kms:GenerateRandom",
          "kms:TagResource",
          "kms:CreateAlias",
          "kms:ListKeyPolicies",
          "kms:ListResourceTags",
          "kms:CreateGrant",
          "kms:RevokeGrant",
          "kms:GetKeyPolicy",
          "kms:ListKeys",
          "kms:ListRetirableGrants",
          "kms:PutKeyPolicy",
          "kms:ListAliases",
          "kms:CancelKeyDeletion",
          "kms:DisableKey",
          "kms:DeleteAlias",
          "kms:DescribeKey",
          "kms:ImportKeyMaterial",
          "kms:UpdateKeyDescription",
          "kms:GetKeyRotationStatus",
          "kms:DeleteImportedKeyMaterial",
          "kms:DisableKeyRotation",
          "kms:UpdateAlias",
          "kms:UntagResource",
          "kms:RetireGrant",
          "kms:EnableKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:EnableKeyRotation",
          "kms:ScheduleKeyDeletion",
          "kms:GetParametersForImport",
          "kms:CreateKey",
        ]
        Resource = "*"
      },
      {
        Sid       = "Allow Cloudtrail use of the key"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyPair",
          "kms:GenerateDataKeyPairWithoutPlaintext",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:ReEncryptFrom",
          "kms:ReEncryptTo",
        ]
        Resource = "*"
      },
    ]
  })
  tags = var.tags
}

resource "aws_kms_alias" "security_hub_alarm_notification_topic_cmk_alias" {
  name          = "alias/compliant-framework/security-hub/sns"
  target_key_id = aws_kms_key.security_hub_alarm_notification_topic_cmk.key_id
}

resource "aws_sns_topic" "security_hub_alarm_notification_topic" {
  name              = "SecurityHub-CIS-Alarms"
  kms_master_key_id = aws_kms_alias.security_hub_alarm_notification_topic_cmk_alias.name
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "security_hub_alarm_notification_topic_email" {
  topic_arn = aws_sns_topic.security_hub_alarm_notification_topic.arn
  protocol  = "email"
  endpoint  = var.notifications_email
}

locals {
  # Map key = CFN logical id in snake_case (without the leading "r").
  cis_metric_filters = {
    security_hub_root_account_metric_filter = { # rSecurityHubRootAccountMetricFilter
      pattern     = "{$.userIdentity.type=\"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType !=\"AwsServiceEvent\"}"
      metric_name = "RootAccount"
    }
    security_hub_root_account_usage_metric_filter = { # rSecurityHubRootAccountUsageMetricFilter
      pattern     = "{$.userIdentity.type=\"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType !=\"AwsServiceEvent\"}"
      metric_name = "RootAccountUsage"
    }
    security_hub_unauthorized_api_calls_metric_filter = { # rSecurityHubUnauthorizedAPICallsMetricFilter
      pattern     = "{($.errorCode=\"*UnauthorizedOperation\") || ($.errorCode=\"AccessDenied*\")}"
      metric_name = "UnauthorizedAPICalls"
    }
    security_hub_console_signin_without_mfa_metric_filter = { # rSecurityHubConsoleSigninWithoutMFAMetricFilter
      pattern     = "{($.eventName=\"ConsoleLogin\") && ($.additionalEventData.MFAUsed !=\"Yes\")}"
      metric_name = "ConsoleSigninWithoutMFA"
    }
    security_hub_iam_policy_changes_metric_filter = { # rSecurityHubIAMPolicyChangesMetricFilter
      pattern     = "{($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy)}"
      metric_name = "IAMPolicyChanges"
    }
    security_hub_cloud_trail_changes_metric_filter = { # rSecurityHubCloudTrailChangesMetricFilter
      pattern     = "{($.eventName=CreateTrail) || ($.eventName=UpdateTrail) || ($.eventName=DeleteTrail) || ($.eventName=StartLogging) || ($.eventName=StopLogging)}"
      metric_name = "CloudTrailChanges"
    }
    security_hub_console_authentication_failure_metric_filter = { # rSecurityHubConsoleAuthenticationFailureMetricFilter
      pattern     = "{($.eventName=ConsoleLogin) && ($.errorMessage=\"Failed authentication\")}"
      metric_name = "ConsoleAuthenticationFailure"
    }
    security_hub_disable_or_delete_cmk_metric_filter = { # rSecurityHubDisableOrDeleteCMKMetricFilter
      pattern     = "{($.eventSource=kms.amazonaws.com) && (($.eventName=DisableKey) || ($.eventName=ScheduleKeyDeletion))}"
      metric_name = "DisableOrDeleteCMK"
    }
    security_hub_s3_bucket_policy_changes_metric_filter = { # rSecurityHubS3BucketPolicyChangesMetricFilter
      pattern     = "{($.eventSource=s3.amazonaws.com) && (($.eventName=PutBucketAcl) || ($.eventName=PutBucketPolicy) || ($.eventName=PutBucketCors) || ($.eventName=PutBucketLifecycle) || ($.eventName=PutBucketReplication) || ($.eventName=DeleteBucketPolicy) || ($.eventName=DeleteBucketCors) || ($.eventName=DeleteBucketLifecycle) || ($.eventName=DeleteBucketReplication))}"
      metric_name = "S3BucketPolicyChanges"
    }
    security_hub_aws_config_changes_metric_filter = { # rSecurityHubAWSConfigChangesMetricFilter
      pattern     = "{($.eventSource=config.amazonaws.com) && (($.eventName=StopConfigurationRecorder) || ($.eventName=DeleteDeliveryChannel) || ($.eventName=PutDeliveryChannel) || ($.eventName=PutConfigurationRecorder))}"
      metric_name = "AWSConfigChanges"
    }
    security_hub_security_group_changes_metric_filter = { # rSecurityHubSecurityGroupChangesMetricFilter
      pattern     = "{($.eventName=AuthorizeSecurityGroupIngress) || ($.eventName=AuthorizeSecurityGroupEgress) || ($.eventName=RevokeSecurityGroupIngress) || ($.eventName=RevokeSecurityGroupEgress) || ($.eventName=CreateSecurityGroup) || ($.eventName=DeleteSecurityGroup)}"
      metric_name = "SecurityGroupChanges"
    }
    security_hub_network_acl_changes_metric_filter = { # rSecurityHubNetworkACLChangesMetricFilter
      pattern     = "{($.eventName=CreateNetworkAcl) || ($.eventName=CreateNetworkAclEntry) || ($.eventName=DeleteNetworkAcl) || ($.eventName=DeleteNetworkAclEntry) || ($.eventName=ReplaceNetworkAclEntry) || ($.eventName=ReplaceNetworkAclAssociation)}"
      metric_name = "NetworkACLChanges"
    }
    security_hub_network_gateway_changes_metric_filter = { # rSecurityHubNetworkGatewayChangesMetricFilter
      pattern     = "{($.eventName=CreateCustomerGateway) || ($.eventName=DeleteCustomerGateway) || ($.eventName=AttachInternetGateway) || ($.eventName=CreateInternetGateway) || ($.eventName=DeleteInternetGateway) || ($.eventName=DetachInternetGateway)}"
      metric_name = "NetworkGatewayChanges"
    }
    security_hub_route_table_changes_metric_filter = { # rSecurityHubRouteTableChangesMetricFilter
      pattern     = "{($.eventName=CreateRoute) || ($.eventName=CreateRouteTable) || ($.eventName=ReplaceRoute) || ($.eventName=ReplaceRouteTableAssociation) || ($.eventName=DeleteRouteTable) || ($.eventName=DeleteRoute) || ($.eventName=DisassociateRouteTable)}"
      metric_name = "RouteTableChanges"
    }
    security_hub_vpc_changes_metric_filter = { # rSecurityHubVPCChangesMetricFilter
      pattern     = "{($.eventName=CreateVpc) || ($.eventName=DeleteVpc) || ($.eventName=ModifyVpcAttribute) || ($.eventName=AcceptVpcPeeringConnection) || ($.eventName=CreateVpcPeeringConnection) || ($.eventName=DeleteVpcPeeringConnection) || ($.eventName=RejectVpcPeeringConnection) || ($.eventName=AttachClassicLinkVpc) || ($.eventName=DetachClassicLinkVpc) || ($.eventName=DisableVpcClassicLink) || ($.eventName=EnableVpcClassicLink)}"
      metric_name = "VPCChanges"
    }
  }
  cis_alarms = {
    security_hub_root_account_alarm = { # rSecurityHubRootAccountAlarm
      alarm_name  = "CIS-1.1-RootAccountUsage"
      description = "Alarm for usage of \"root\" account"
      metric_name = "RootAccountUsage"
    }
    security_hub_root_account_usage_alarm = { # rSecurityHubRootAccountUsageAlarm
      alarm_name  = "CIS-3.3-RootAccountUsage"
      description = "Alarm for usage of \"root\" account"
      metric_name = "RootAccountUsage"
    }
    security_hub_unauthorized_api_calls_alarm = { # rSecurityHubUnauthorizedAPICallsAlarm
      alarm_name  = "CIS-3.1-UnauthorizedAPICalls"
      description = "Alarm for unauthorized API calls"
      metric_name = "UnauthorizedAPICalls"
    }
    security_hub_console_signin_without_mfa_alarm = { # rSecurityHubConsoleSigninWithoutMFAAlarm
      alarm_name  = "CIS-3.2-ConsoleSigninWithoutMFA"
      description = "Alarm for AWS Management Console sign-in without MFA"
      metric_name = "ConsoleSigninWithoutMFA"
    }
    security_hub_iam_policy_changes_alarm = { # rSecurityHubIAMPolicyChangesAlarm
      alarm_name  = "CIS-3.4-IAMPolicyChanges"
      description = "Alarm for IAM policy changes"
      metric_name = "IAMPolicyChanges"
    }
    security_hub_cloud_trail_changes_alarm = { # rSecurityHubCloudTrailChangesAlarm
      alarm_name  = "CIS-3.5-CloudTrailChanges"
      description = "Alarm for CloudTrail configuration changes"
      metric_name = "CloudTrailChanges"
    }
    security_hub_console_authentication_failure_alarm = { # rSecurityHubConsoleAuthenticationFailureAlarm
      alarm_name  = "CIS-3.6-ConsoleAuthenticationFailure"
      description = "Alarm exist for AWS Management Console authentication failures"
      metric_name = "ConsoleAuthenticationFailure"
    }
    security_hub_disable_or_delete_cmk_alarm = { # rSecurityHubDisableOrDeleteCMKAlarm
      alarm_name  = "CIS-3.7-DisableOrDeleteCMK"
      description = "Alarm for disabling or scheduled deletion of customer created CMKs"
      metric_name = "DisableOrDeleteCMK"
    }
    security_hub_s3_bucket_policy_changes_alarm = { # rSecurityHubS3BucketPolicyChangesAlarm
      alarm_name  = "CIS-3.8-S3BucketPolicyChanges."
      description = "Alarm for S3 bucket policy changes"
      metric_name = "S3BucketPolicyChanges"
    }
    security_hub_aws_config_changes_alarm = { # rSecurityHubAWSConfigChangesAlarm
      alarm_name  = "CIS-3.9-AWSConfigChanges"
      description = "Alarm for AWS Config configuration changes"
      metric_name = "AWSConfigChanges"
    }
    security_group_changes_alarm = { # rSecurityGroupChangesAlarm
      alarm_name  = "CIS-3.10-SecurityGroupChanges"
      description = "Alarm for security group changes"
      metric_name = "SecurityGroupChanges"
    }
    security_hub_network_acl_changes_alarm = { # rSecurityHubNetworkACLChangesAlarm
      alarm_name  = "CIS-3.11-NetworkACLChanges"
      description = "Alarm for changes to Network Access Control Lists (NACL)"
      metric_name = "NetworkACLChanges"
    }
    security_hub_network_gateway_changes_alarm = { # rSecurityHubNetworkGatewayChangesAlarm
      alarm_name  = "CIS-3.12-NetworkGatewayChanges"
      description = "Alarm for changes to network gateways"
      metric_name = "NetworkGatewayChanges"
    }
    route_table_changes_alarm = { # rRouteTableChangesAlarm
      alarm_name  = "CIS-3.13-RouteTableChanges"
      description = "Alarm for route table changes"
      metric_name = "RouteTableChanges"
    }
    security_hub_vpc_changes_alarm = { # rSecurityHubVPCChangesAlarm
      alarm_name  = "CIS-3.14-VPCChanges"
      description = "Alarm for VPC changes"
      metric_name = "VPCChanges"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "cis" {
  for_each = local.cis_metric_filters

  name           = each.value.metric_name
  log_group_name = aws_cloudwatch_log_group.cloudtrail_cloudwatch_log_group.name
  pattern        = each.value.pattern

  metric_transformation {
    namespace = "LogMetrics"
    name      = each.value.metric_name
    value     = "1"
  }
}

# NOTE: CIS-1.1-RootAccountUsage watches metric "RootAccountUsage" (not "RootAccount" emitted by the 1.1 filter);
# kept exactly as in the source template.
resource "aws_cloudwatch_metric_alarm" "cis" {
  for_each = local.cis_alarms

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.description
  alarm_actions       = [aws_sns_topic.security_hub_alarm_notification_topic.arn]
  metric_name         = each.value.metric_name
  namespace           = "LogMetrics"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  tags                = var.tags
}
