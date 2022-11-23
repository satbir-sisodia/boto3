import json
import boto3

AWS_REGION = "ap-south-1"

def lambda_handler(event, context):
    # TODO implement
    
    EC2_RESOURCE = boto3.resource('ec2', region_name=AWS_REGION)
    EC2_CLIENT = boto3.client('ec2', region_name=AWS_REGION)
    
    
    response = EC2_CLIENT.describe_addresses(

    )
    
    public_ip = response['Addresses'][0]['PublicIp']
    
    print ("public_ip =", public_ip)
    
    return public_ip