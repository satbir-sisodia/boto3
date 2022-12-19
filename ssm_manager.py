import boto3
import os
import json
import time


AWS_REGION = "ap-south-1"


def lambda_handler(event, context):

    # boto3 client
    client = boto3.client("ec2", region_name=AWS_REGION)
    ssm = boto3.client("ssm", region_name=AWS_REGION)

    # getting instance information
    describeInstance = client.describe_instances()

    InstanceId = []
    # fetchin instance id of the running instances
    for i in describeInstance["Reservations"]:
        for instance in i["Instances"]:
            if instance["State"]["Name"] == "running":
                InstanceId.append(instance["InstanceId"])

    # looping through instance ids

    for instanceid in InstanceId:
        # command to be executed on instance
        response = ssm.send_command(
            InstanceIds=[instanceid],
            DocumentName="AWS-RunShellScript",
            Parameters={
                "commands": ["echo '<h1>Success! the webhost virtual host is totally fine working</h1>' > /var/www/html/index.html"]},)

        # fetching command id for the output
        command_id = response["Command"]["CommandId"]

        time.sleep(3)

        # fetching command output
        output = ssm.get_command_invocation(
            CommandId=command_id, InstanceId=instanceid)

        print(output)
        print(output['StandardOutputContent'])

    return {
        "statusCode": 200,
        "body": json.dumps("Message deployed successfully")

    }
