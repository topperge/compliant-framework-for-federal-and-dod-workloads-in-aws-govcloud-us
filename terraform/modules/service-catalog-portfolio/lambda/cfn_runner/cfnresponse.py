# Minimal equivalent of the "cfnresponse" helper module that AWS Lambda injects only for
# CloudFormation inline (ZipFile) functions. Packaged here because this function is deployed from a zip.
import json
import urllib.request

SUCCESS = "SUCCESS"
FAILED = "FAILED"


def send(event, context, responseStatus, responseData, physicalResourceId=None, noEcho=False, reason=None):
  responseUrl = event['ResponseURL']

  responseBody = {
      'Status': responseStatus,
      'Reason': reason or "See the details in CloudWatch Log Stream: {}".format(context.log_stream_name),
      'PhysicalResourceId': physicalResourceId or context.log_stream_name,
      'StackId': event['StackId'],
      'RequestId': event['RequestId'],
      'LogicalResourceId': event['LogicalResourceId'],
      'NoEcho': noEcho,
      'Data': responseData,
  }

  json_responseBody = json.dumps(responseBody, default=str).encode('utf-8')
  print("Response body:")
  print(json_responseBody.decode('utf-8'))

  req = urllib.request.Request(
      responseUrl,
      data=json_responseBody,
      method='PUT',
      headers={'content-type': '', 'content-length': str(len(json_responseBody))},
  )
  try:
    with urllib.request.urlopen(req) as response:
      print("Status code: {}".format(response.status))
  except Exception as e:
    print("send(..) failed executing request: {}".format(e))
