import json
import boto3

AWS_REGION = "ap-south-1"
EC2_CLIENT = boto3.client('ec2', region_name=AWS_REGION)
EC2_RESOURCE = boto3.resource('ec2', region_name=AWS_REGION)

def check_post_request(event, key):
  request_body = event.get('body')
  if request_body is not None:
    request_body = json.loads(request_body)
    value = request_body.get(key)
    if value and str(value).strip():
      return value

  return None
  
def start_stop(event, context):
    responseResponse = {}
    responseResponse['headers'] = {}
    responseResponse['headers']['Content-type'] = "application/json"
    responseMessage = {}
    request_body = event.get('body')
    
    if request_body is not None:
        IPAddress = check_post_request(event, 'ipAddress')
        action = check_post_request(event, 'action')
        if IPAddress is None or action is None:
            responseResponse['statusCode'] = 209
            responseMessage['message'] = "Missing required Fields"
        else :
            
            INSTANCE_IP = IPAddress
            filters = [
                {'Name': 'public-ip', 'Values': [INSTANCE_IP]}
            ]
            response = EC2_CLIENT.describe_addresses(Filters=filters)
            
            if response["Addresses"][0]["InstanceId"] is None:
                responseResponse['statusCode'] = 404
                responseMessage['message'] = "Instance not found"
            else:
                instanceID = response["Addresses"][0]["InstanceId"];
                instance = EC2_RESOURCE.Instance(instanceID)
                if(action == "start"):
                    isUpdated = True
                    instance.start()
                    instance.wait_until_running()
                    responseResponse['statusCode'] = 200
                    responseMessage['message'] = "Instance started successfully"
                else:
                    isUpdated = True
                    instance.stop() 
                    instance.wait_until_stopped()
                    responseResponse['statusCode'] = 200
                    responseMessage['message'] = "Instance stopped successfully"
    else:        
        responseResponse['statusCode'] = 209
        responseMessage['message'] = "Invalid request Type"
    
    
    responseResponse['body'] = json.dumps(responseMessage)    
    return responseResponse 
