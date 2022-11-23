import boto3
import json
import random


AWS_REGION = "ap-south-1"
KEY_PAIR_NAME = 'instance-key'
AMI_ID = 'ami-062df10d14676e201'  # amazon linux
INSTANCE_TYPE = 't2.micro'
#SUBNET_ID = 'subnet-0984555689f5894d8'
#SECURITY_GROUP_ID = 'sg-01304974040835e2f'
INSTANCE_PROFILE = 'ec2CodeDeploy'


def lambda_handler(event, context):

    init_script = """#!/bin/bash
        sudo apt -y update
        sudo apt -y install ruby
        sudo apt -y install wget
        cd /home/ubuntu
        sudo apt install python3-pip
        sudo pip install awscli
        sudo apt-get install  apache2 -y
        service apache2 start
        echo “Hello World from $(hostname -f)” > /var/www/html/index.html
        sudo wget https://tarbuildbucket.s3.ap-south-1.amazonaws.com/aws-themes.zip
        """

    EC2_RESOURCE = boto3.resource('ec2', region_name=AWS_REGION)
    EC2_CLIENT = boto3.client('ec2', region_name=AWS_REGION)

    x = random.randint(0, 255)
    ec2name = 'my-ec2-instance'
    ec2name += str(x)

    instances = EC2_RESOURCE.create_instances(
        MinCount=1,
        MaxCount=1,
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
                        'Value': ec2name
                    },
                ]
            },
        ]
    )

    print("New instance created.")
    instance_id = (instances[0].id)
    print("instace-id =", instance_id)

    for instance in instances:
        print(f'EC2 instance "{instance.id}" has been launched')
        instance.wait_until_running()

        EC2_CLIENT.associate_iam_instance_profile(
            IamInstanceProfile={'Name': INSTANCE_PROFILE},
            InstanceId=instance_id,
        )

        print(f'EC2 Instance Profile "{INSTANCE_PROFILE}" has been attached')

        eipname = 'my-elastic-ip'
        eipname += str(x)

    allocation = EC2_CLIENT.allocate_address(
        Domain='vpc',
        TagSpecifications=[
            {
                'ResourceType': 'elastic-ip',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': eipname
                    },
                ]
            },
        ]
    )

    allocation_id = allocation["AllocationId"]
    public_ip = allocation["PublicIp"]

    print(f'Allocation ID =', allocation_id)
    print(f' Elastic IP =', public_ip, 'has been allocated')

    response = EC2_CLIENT.associate_address(
        InstanceId=instance_id,
        AllocationId=allocation_id
    )

    print(f'Elastic-Ip {public_ip} associated with the instance {instance_id}')

    return {
        'statusCode': 200,
        'body': f'Elastic-Ip {public_ip} associated with the instance {instance_id}'
    }
