# CompliantFramework-CfnRunner
#
# Backs the Custom::TenantTwoTierVpc / Custom::rAttachTenant resources of the Service Catalog
# "Two Tier VPC" product. It assumes <CFN_RUNNER_ACCOUNT_ACCESS_ROLE> in the target account and
# creates/updates/deletes a CloudFormation stack there, returning the stack outputs.
#
# Extracted from the inline ZipFile code of service-catalog/portfolio.yml. The CloudFormation
# !Sub substitutions (${AWS::Partition}, ${pCfnRunnerAccountAccessRole}) are now environment variables.
import json
import os

import boto3
from botocore.exceptions import ClientError

import cfnresponse

PARTITION = os.environ['PARTITION']
CFN_RUNNER_ACCOUNT_ACCESS_ROLE = os.environ['CFN_RUNNER_ACCOUNT_ACCESS_ROLE']


def get_outputs(cfn_client, stack_name):
  response = cfn_client.describe_stacks(StackName=stack_name)
  responseData = {}
  for stack in response['Stacks']:
    if 'Outputs' in stack:
      for output in stack['Outputs']:
        responseData[output['OutputKey']] = output['OutputValue']
  return responseData


def handler(event, context):
  print('event:')
  print(json.dumps(event))

  account_id = event['ResourceProperties']['AccountId']
  template_url = event['ResourceProperties']['TemplateUrl']
  stack_name = event['ResourceProperties']['StackName']

  sts_client = boto3.client('sts')
  assumed_role = sts_client.assume_role(
      RoleArn=f'arn:{PARTITION}:iam::{account_id}:role/{CFN_RUNNER_ACCOUNT_ACCESS_ROLE}',
      RoleSessionName=f'CfnRunner'
  )
  cfn_client = boto3.client(
      'cloudformation',
      aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
      aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
      aws_session_token=assumed_role['Credentials']['SessionToken']
  )

  parameters = []
  capabilities = []

  if 'Parameters' in event['ResourceProperties']:
    for parameter in event['ResourceProperties']['Parameters']:
      parameters.append({'ParameterKey': parameter['Key'], 'ParameterValue': parameter['Value']})
  print(parameters)

  if 'Capabilities' in event['ResourceProperties']:
    capabilities.extend(event['ResourceProperties']['Capabilities'])
  print(capabilities)

  if event['RequestType'] == 'Create':
    try:
      response = cfn_client.create_stack(
          StackName=stack_name,
          TemplateURL=template_url,
          Parameters=parameters,
          Capabilities=capabilities
      )
      print('create_stack response:')
      print(json.dumps(response))
      waiter = cfn_client.get_waiter('stack_create_complete')
      waiter.wait(StackName=stack_name, WaiterConfig={'Delay': 30, 'MaxAttempts': 20})
      responseData = get_outputs(cfn_client, stack_name)
      cfnresponse.send(event, context, cfnresponse.SUCCESS, responseData)
    except ClientError as ex:
      print(ex)
      cfnresponse.send(event, context, cfnresponse.FAILED, {})
  elif event['RequestType'] == 'Update':
    try:
      response = cfn_client.update_stack(
          StackName=stack_name,
          TemplateURL=template_url,
          Parameters=parameters,
          Capabilities=capabilities
      )
      print('create_stack response:')
      print(json.dumps(response))
      waiter = cfn_client.get_waiter('stack_update_complete')
      waiter.wait(StackName=stack_name, WaiterConfig={'Delay': 30, 'MaxAttempts': 20})
      physical_resource_id = event['PhysicalResourceId']
      responseData = get_outputs(cfn_client, stack_name)
      cfnresponse.send(event, context, cfnresponse.SUCCESS, responseData, physicalResourceId=physical_resource_id)
    except ClientError as ex:
      print(ex)
      cfnresponse.send(event, context, cfnresponse.FAILED, {})
  elif event['RequestType'] == 'Delete':
    response = cfn_client.delete_stack(
        StackName=stack_name
    )
    print('delete_stack response:')
    print(json.dumps(response))
    waiter = cfn_client.get_waiter('stack_delete_complete')
    waiter.wait(StackName=stack_name, WaiterConfig={'Delay': 30, 'MaxAttempts': 20})
    cfnresponse.send(event, context, cfnresponse.SUCCESS, response)
  else:
    cfnresponse.send(event, context, cfnresponse.FAILED, {})
  return {}
