import boto3
import json


AWS_REGION = "ap-south-1"
KEY_PAIR_NAME = 'instance-key'
AMI_ID = 'ami-062df10d14676e201' # amazon linux
INSTANCE_TYPE = 't2.micro'
#SUBNET_ID = 'subnet-0984555689f5894d8'
#SECURITY_GROUP_ID = 'sg-01304974040835e2f'
INSTANCE_PROFILE = 'ec2CodeDeploy'

def lambda_handler (event, context):
    
    init_script = """#!/bin/bash
        sudo yum -y update
        sudo yum -y install ruby
        sudo yum -y install wget
        sudo apt-get install  apache2 -y
        service apache2 start
        echo “Hello World from $(hostname -f)” > /var/www/html/index.html
        
        sudo wget https://tarbuildbucket.s3.ap-south-1.amazonaws.com/token-sale1.tar
        
        """

    EC2_RESOURCE = boto3.resource('ec2', region_name=AWS_REGION)
    EC2_CLIENT = boto3.client('ec2', region_name=AWS_REGION)

    instances = EC2_RESOURCE.create_instances(
        MinCount = 1,
        MaxCount = 1,
        ImageId=AMI_ID,
        InstanceType=INSTANCE_TYPE,
        KeyName=KEY_PAIR_NAME,
        UserData=init_script,
        TagSpecifications=[
            {
                'ResourceType': 'instance',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': 'my-ec2-instance'
                    },
                ]
            },
        ]
    )
    
    print ("New instance created.")
    instance_id = (instances[0].id)
    print ("instace-id =", instance_id)
    
    for instance in instances:
        print(f'EC2 instance "{instance.id}" has been launched')
        instance.wait_until_running()
        
        EC2_CLIENT.associate_iam_instance_profile(
            IamInstanceProfile = {'Name': INSTANCE_PROFILE},
            InstanceId = instance_id,
        )

        print(f'EC2 Instance Profile "{INSTANCE_PROFILE}" has been attached')
        
    allocation = EC2_CLIENT.allocate_address(
        Domain='vpc',
        TagSpecifications=[
            {
                'ResourceType': 'elastic-ip',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': 'my-elastic-ip'
                    },
                ]
            },
        ]
    )

    print(f'Allocation ID {allocation["AllocationId"]}')
    print(f' Elastic IP {allocation["PublicIp"]} has been allocated')
    
    response = EC2_CLIENT.describe_addresses(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': ['my-elastic-ip']
            }
        ]
    )

    public_ip = response['Addresses'][0]['PublicIp']
    allocation_id = response['Addresses'][0]['AllocationId']

    response = EC2_CLIENT.associate_address(
        InstanceId=instance_id,
        AllocationId=allocation_id
    )

    print(f'Elastic-Ip {public_ip} associated with the instance {instance_id}')
    
    
    sns=boto3.client("sns")
    
    msg = f'Elastic-Ip {public_ip} associated with the instance {instance_id}'
    
    response = sns.publish(TopicArn='arn:aws:sns:ap-south-1:627344691952:demo',Message=msg)
    
    print(response)

    

    return {
        'statusCode': 200,
        'body': f'Elastic-Ip {public_ip} associated with the instance {instance_id}'
    }

