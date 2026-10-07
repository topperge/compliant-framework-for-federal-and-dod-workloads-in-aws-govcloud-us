#
# CIS AWS Foundations Benchmark metric filters (primary region only) and alarms (every region)
#
locals {
  cis_checks = {
    # 1.1 - Avoid the use of the "root" account
    # NOTE: as in the source template, the filter emits RootAccount but the alarm watches RootAccountUsage.
    root_account = {
      filter_name       = "CIS-1.1-RootAccount"
      pattern           = "{$.userIdentity.type=\"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType !=\"AwsServiceEvent\"}"
      metric_name       = "RootAccount"
      alarm_name        = "CIS-1.1-RootAccountUsage"
      alarm_description = "Alarm for usage of \"root\" account"
      alarm_metric_name = "RootAccountUsage"
    }
    # 3.3 - Ensure a log metric filter and alarm exist for usage of "root" account
    root_account_usage = {
      filter_name       = "CIS-3.3-RootAccountUsage"
      pattern           = "{$.userIdentity.type=\"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType !=\"AwsServiceEvent\"}"
      metric_name       = "RootAccountUsage"
      alarm_name        = "CIS-3.3-RootAccountUsage"
      alarm_description = "Alarm for usage of \"root\" account"
      alarm_metric_name = "RootAccountUsage"
    }
    # 3.1 - Ensure a log metric filter and alarm exist for unauthorized API calls
    unauthorized_api_calls = {
      filter_name       = "CIS-3.1-UnauthorizedAPICalls"
      pattern           = "{($.errorCode=\"*UnauthorizedOperation\") || ($.errorCode=\"AccessDenied*\")}"
      metric_name       = "UnauthorizedAPICalls"
      alarm_name        = "CIS-3.1-UnauthorizedAPICalls"
      alarm_description = "Alarm for unauthorized API calls"
      alarm_metric_name = "UnauthorizedAPICalls"
    }
    # 3.2 - Ensure a log metric filter and alarm exist for AWS Management Console sign-in without MFA
    console_signin_without_mfa = {
      filter_name       = "CIS-3.2-ConsoleSigninWithoutMFA"
      pattern           = "{($.eventName=\"ConsoleLogin\") && ($.additionalEventData.MFAUsed !=\"Yes\")}"
      metric_name       = "ConsoleSigninWithoutMFA"
      alarm_name        = "CIS-3.2-ConsoleSigninWithoutMFA"
      alarm_description = "Alarm for AWS Management Console sign-in without MFA"
      alarm_metric_name = "ConsoleSigninWithoutMFA"
    }
    # 3.4 - Ensure a log metric filter and alarm exist for IAM policy changes
    iam_policy_changes = {
      filter_name       = "CIS-3.4-IAMPolicyChanges"
      pattern           = "{($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy)}"
      metric_name       = "IAMPolicyChanges"
      alarm_name        = "CIS-3.4-IAMPolicyChanges"
      alarm_description = "Alarm for IAM policy changes"
      alarm_metric_name = "IAMPolicyChanges"
    }
    # 3.5 - Ensure a log metric filter and alarm exist for CloudTrail configuration changes
    cloudtrail_changes = {
      filter_name       = "CIS-3.5-CloudTrailChanges"
      pattern           = "{($.eventName=CreateTrail) || ($.eventName=UpdateTrail) || ($.eventName=DeleteTrail) || ($.eventName=StartLogging) || ($.eventName=StopLogging)}"
      metric_name       = "CloudTrailChanges"
      alarm_name        = "CIS-3.5-CloudTrailChanges"
      alarm_description = "Alarm for CloudTrail configuration changes"
      alarm_metric_name = "CloudTrailChanges"
    }
    # 3.6 - Ensure a log metric filter and alarm exist for AWS Management Console authentication failures
    console_authentication_failure = {
      filter_name       = "CIS-3.6-ConsoleAuthenticationFailure"
      pattern           = "{($.eventName=ConsoleLogin) && ($.errorMessage=\"Failed authentication\")}"
      metric_name       = "ConsoleAuthenticationFailure"
      alarm_name        = "CIS-3.6-ConsoleAuthenticationFailure"
      alarm_description = "Alarm exist for AWS Management Console authentication failures"
      alarm_metric_name = "ConsoleAuthenticationFailure"
    }
    # 3.7 - Ensure a log metric filter and alarm exist for disabling or scheduled deletion of customer created CMKs
    disable_or_delete_cmk = {
      filter_name       = "CIS-3.7-DisableOrDeleteCMK"
      pattern           = "{($.eventSource=kms.amazonaws.com) && (($.eventName=DisableKey) || ($.eventName=ScheduleKeyDeletion))}"
      metric_name       = "DisableOrDeleteCMK"
      alarm_name        = "CIS-3.7-DisableOrDeleteCMK"
      alarm_description = "Alarm for disabling or scheduled deletion of customer created CMKs"
      alarm_metric_name = "DisableOrDeleteCMK"
    }
    # 3.8 - Ensure a log metric filter and alarm exist for S3 bucket policy changes
    s3_bucket_policy_changes = {
      filter_name       = "CIS-3.8-S3BucketPolicyChanges"
      pattern           = "{($.eventSource=s3.amazonaws.com) && (($.eventName=PutBucketAcl) || ($.eventName=PutBucketPolicy) || ($.eventName=PutBucketCors) || ($.eventName=PutBucketLifecycle) || ($.eventName=PutBucketReplication) || ($.eventName=DeleteBucketPolicy) || ($.eventName=DeleteBucketCors) || ($.eventName=DeleteBucketLifecycle) || ($.eventName=DeleteBucketReplication))}"
      metric_name       = "S3BucketPolicyChanges"
      alarm_name        = "CIS-3.8-S3BucketPolicyChanges." # trailing dot kept from source (physical name)
      alarm_description = "Alarm for S3 bucket policy changes"
      alarm_metric_name = "S3BucketPolicyChanges"
    }
    # 3.9 - Ensure a log metric filter and alarm exist for AWS Config configuration changes
    aws_config_changes = {
      filter_name       = "CIS-3.9-AWSConfigChanges"
      pattern           = "{($.eventSource=config.amazonaws.com) && (($.eventName=StopConfigurationRecorder) || ($.eventName=DeleteDeliveryChannel) || ($.eventName=PutDeliveryChannel) || ($.eventName=PutConfigurationRecorder))}"
      metric_name       = "AWSConfigChanges"
      alarm_name        = "CIS-3.9-AWSConfigChanges"
      alarm_description = "Alarm for AWS Config configuration changes"
      alarm_metric_name = "AWSConfigChanges"
    }
    # 3.10 - Ensure a log metric filter and alarm exist for security group changes
    security_group_changes = {
      filter_name       = "CIS-3.10-SecurityGroupChanges"
      pattern           = "{($.eventName=AuthorizeSecurityGroupIngress) || ($.eventName=AuthorizeSecurityGroupEgress) || ($.eventName=RevokeSecurityGroupIngress) || ($.eventName=RevokeSecurityGroupEgress) || ($.eventName=CreateSecurityGroup) || ($.eventName=DeleteSecurityGroup)}"
      metric_name       = "SecurityGroupChanges"
      alarm_name        = "CIS-3.10-SecurityGroupChanges"
      alarm_description = "Alarm for security group changes"
      alarm_metric_name = "SecurityGroupChanges"
    }
    # 3.11 - Ensure a log metric filter and alarm exist for changes to Network Access Control Lists (NACL)
    network_acl_changes = {
      filter_name       = "CIS-3.11-NetworkACLChanges"
      pattern           = "{($.eventName=CreateNetworkAcl) || ($.eventName=CreateNetworkAclEntry) || ($.eventName=DeleteNetworkAcl) || ($.eventName=DeleteNetworkAclEntry) || ($.eventName=ReplaceNetworkAclEntry) || ($.eventName=ReplaceNetworkAclAssociation)}"
      metric_name       = "NetworkACLChanges"
      alarm_name        = "CIS-3.11-NetworkACLChanges"
      alarm_description = "Alarm for changes to Network Access Control Lists (NACL)"
      alarm_metric_name = "NetworkACLChanges"
    }
    # 3.12 - Ensure a log metric filter and alarm exist for changes to network gateways
    network_gateway_changes = {
      filter_name       = "CIS-3.12-NetworkGatewayChanges"
      pattern           = "{($.eventName=CreateCustomerGateway) || ($.eventName=DeleteCustomerGateway) || ($.eventName=AttachInternetGateway) || ($.eventName=CreateInternetGateway) || ($.eventName=DeleteInternetGateway) || ($.eventName=DetachInternetGateway)}"
      metric_name       = "NetworkGatewayChanges"
      alarm_name        = "CIS-3.12-NetworkGatewayChanges"
      alarm_description = "Alarm for changes to network gateways"
      alarm_metric_name = "NetworkGatewayChanges"
    }
    # 3.13 - Ensure a log metric filter and alarm exist for route table changes
    route_table_changes = {
      filter_name       = "CIS-3.13-RouteTableChanges"
      pattern           = "{($.eventName=CreateRoute) || ($.eventName=CreateRouteTable) || ($.eventName=ReplaceRoute) || ($.eventName=ReplaceRouteTableAssociation) || ($.eventName=DeleteRouteTable) || ($.eventName=DeleteRoute) || ($.eventName=DisassociateRouteTable)}"
      metric_name       = "RouteTableChanges"
      alarm_name        = "CIS-3.13-RouteTableChanges"
      alarm_description = "Alarm for route table changes"
      alarm_metric_name = "RouteTableChanges"
    }
    # 3.14 - Ensure a log metric filter and alarm exist for VPC changes
    vpc_changes = {
      filter_name       = "CIS-3.14-VPCChanges"
      pattern           = "{($.eventName=CreateVpc) || ($.eventName=DeleteVpc) || ($.eventName=ModifyVpcAttribute) || ($.eventName=AcceptVpcPeeringConnection) || ($.eventName=CreateVpcPeeringConnection) || ($.eventName=DeleteVpcPeeringConnection) || ($.eventName=RejectVpcPeeringConnection) || ($.eventName=AttachClassicLinkVpc) || ($.eventName=DetachClassicLinkVpc) || ($.eventName=DisableVpcClassicLink) || ($.eventName=EnableVpcClassicLink)}"
      metric_name       = "VPCChanges"
      alarm_name        = "CIS-3.14-VPCChanges"
      alarm_description = "Alarm for VPC changes"
      alarm_metric_name = "VPCChanges"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "cis" {
  for_each = local.is_primary_region ? local.cis_checks : {}

  name           = each.value.filter_name
  log_group_name = var.cloudtrail_cloudwatch_log_group_name
  pattern        = each.value.pattern

  metric_transformation {
    namespace = "LogMetrics"
    name      = each.value.metric_name
    value     = "1"
  }

  lifecycle {
    precondition {
      condition     = var.cloudtrail_cloudwatch_log_group_name != ""
      error_message = "cloudtrail_cloudwatch_log_group_name is required in the primary region."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cis" {
  for_each = local.cis_checks

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.alarm_description
  alarm_actions       = [aws_sns_topic.security_hub_alarm_notification.arn]
  metric_name         = each.value.alarm_metric_name
  namespace           = "LogMetrics"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  tags                = var.tags
}
