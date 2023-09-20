#!/usr/bin/bash

export SSH_KEY="~/.ssh/ucs-nightly.pem"

export SSM_SUBNET_ID="/unity-sds/u-cs/nightly/publicsubnetid"
export SSM_INSTANCE_TYPE="/unity-sds/u-cs/nightly/instancetype"
export SSM_SECURITY_GROUP_ID="/unity-sds/u-cs/nightly/securitygroup"
export SSM_KEYPAIR_NAME="/unity-sds/u-cs/nightly/keypairname"
export SSM_AMI_ID="/mcp/amis/ubuntu2004"


SUBNET_ID=$(aws ssm get-parameter --name ${SSM_SUBNET_ID}                 |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
INSTANCE_TYPE=$(aws ssm get-parameter --name ${SSM_INSTANCE_TYPE}         |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
KEYPAIR_NAME=$(aws ssm get-parameter --name ${SSM_KEYPAIR_NAME}           |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
AMI_ID=$(aws ssm get-parameter --name ${SSM_AMI_ID}                       |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
SECURITY_GROUP_ID=$(aws ssm get-parameter --name ${SSM_SECURITY_GROUP_ID} |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')

if [ -z "$SUBNET_ID" ]
then
    echo "ERROR: Could not read Subnet ID from SSM.  Does the key [$SSM_SUBNET_ID] exist?"
    exit
fi

if [ -z "$INSTANCE_TYPE" ] 
then 
    echo "ERROR: Could not read Instance Type from SSM.  Does the key [$SSM_INSTANCE_TYPE] exist?"
    exit
fi

if [ -z "$KEYPAIR_NAME" ] 
then 
    echo "ERROR: Could not read Key Pair Name from SSM.  Does the key [$SSM_KEYPAIR_NAME] exist?"
    exit
fi

if [ -z "$AMI_ID" ] 
then 
    echo "ERROR: Could not read AMI ID from SSM.  Does the key [$SSM_AMI_ID] exist?"
    exit
fi



rm nightly_output.txt
touch nightly_output.txt

aws ec2 run-instances \
    --image-id ${AMI_ID} \
    --count 1 \
    --instance-type ${INSTANCE_TYPE} \
    --key-name ${KEYPAIR_NAME} \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --subnet-id ${SUBNET_ID} \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=ucs-nightly-test-management-console},{Key=ServiceArea,Value=U-CS}]' > output.txt

INSTANCE_ID=$(grep InstanceId output.txt |sed 's/^.*: "//' | sed 's/".*$//')
echo "INSTANCE_ID=$INSTANCE_ID">NIGHTLY.ENV

echo "Instance ID: $INSTANCE_ID" >> nightly_output.txt
echo "Instance ID: $INSTANCE_ID"

## Wait for startup
INSTANCE_STATUS=""

while [ -z "$INSTANCE_STATUS" ]
do
   echo "Checking Instance [${INSTANCE_ID}] Status..." >> nightly_output.txt
   echo "Checking Instance [${INSTANCE_ID}] Status..."

   aws ec2 describe-instance-status --instance-id $INSTANCE_ID > status.txt
   INSTANCE_STATUS=$(cat status.txt |grep '"Status": "ok"')
   sleep 10
done


## This is where some stuff should go

## Get the information needed to connect to the new instance
aws ec2 describe-instances --instance-id $INSTANCE_ID > status.txt
IP_ADDRESS=$(grep PrivateIpAddress status.txt |sed 's/^.*: "//' | sed 's/".*$//' |head -n 1)
echo "IP_ADDRESS=$IP_ADDRESS">>NIGHTLY.ENV

IP_ADDRESS_PUBLIC=$(grep PublicIpAddress status.txt |sed 's/^.*: "//' | sed 's/".*$//' |head -n 1)
echo "IP_ADDRESS_PUBLIC=$IP_ADDRESS_PUBLIC">>NIGHTLY.ENV

