#!/usr/bin/bash

export SSH_KEY="~/.ssh/ucs-nightly.pem"

export SSM_VPC_ID           ="/unity-sds/u-cs/nightly/vpc-id"
export SSM_PUB_SUBNET1      ="/unity-sds/u-cs/nightly/publicsubnet1"
export SSM_PUB_SUBNET2      ="/unity-sds/u-cs/nightly/publicsubnet2"
export SSM_PRIV_SUBNET1     ="/unity-sds/u-cs/nightly/privatesubnet1"
export SSM_PRIV_SUBNET2     ="/unity-sds/u-cs/nightly/privatesubnet2"
export SSM_KEYPAIR_NAME     ="/unity-sds/u-cs/nightly/keypairname"
export SSM_INSTANCE_TYPE    ="/unity-sds/u-cs/nightly/instancetype"
export SSM_PRIVILEGED_POLICY="/unity-sds/u-cs/nightly/privelegedpolicyname"
export SSM_GITHUB_TOKEN     ="/unity-sds/u-cs/nightly/githubtoken"
export SSM_VENUE            ="/unity-sds/u-cs/nightly/venue"


#   --parameters ParameterKey=VPCID,ParameterValue=${VPCID} \
#     ParameterKey=PublicSubnetID1,ParameterValue=${PublicSubnetID1} \
#     ParameterKey=PublicSubnetID2,ParameterValue=${PublicSubnetID2} \
#     ParameterKey=PrivateSubnetID1,ParameterValue=${PrivateSubnetID1} \
#     ParameterKey=PrivateSubnetID2,ParameterValue=${PrivateSubnetID2} \
#     ParameterKey=KeyPairName,ParameterValue=${KeyPairName} \
#     ParameterKey=InstanceType,ParameterValue=${InstanceType} \
#     ParameterKey=PrivilegedPolicyName,ParameterValue=${PrivilegedPolicyName} \
#     ParameterKey=GithubToken,ParameterValue=${GithubToken} \
#     ParameterKey=Venue,ParameterValue=${Venue} \



VPCID=$(aws ssm get-parameter                --name ${SSM_VPC_ID}            |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PublicSubnetID1=$(aws ssm get-parameter      --name ${SSM_PUB_SUBNET1}       |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PublicSubnetID2=$(aws ssm get-parameter      --name ${SSM_PUB_SUBNET2}       |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PrivateSubnetID1=$(aws ssm get-parameter     --name ${SSM_PRIV_SUBNET1}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PrivateSubnetID2=$(aws ssm get-parameter     --name ${SSM_PRIV_SUBNET2}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
KeyPairName=$(aws ssm get-parameter          --name ${SSM_KEYPAIR_NAME}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
InstanceType=$(aws ssm get-parameter         --name ${SSM_INSTANCE_TYPE}     |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PrivilegedPolicyName=$(aws ssm get-parameter --name ${SSM_PRIVILEGED_POLICY} |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
GithubToken=$(aws ssm get-parameter          --name ${SSM_GITHUB_TOKEN}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
Venue=$(aws ssm get-parameter                --name ${SSM_VENUE}             |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')

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


aws cloudformation create-stack \
  --stack-name unity-cs-nightly-management-console \
  --template-body file://template.yml \
  --capabilities CAPABILITY_IAM \
  --parameters ParameterKey=VPCID,ParameterValue=${VPCID} \
    ParameterKey=PublicSubnetID1,ParameterValue=${PublicSubnetID1} \
    ParameterKey=PublicSubnetID2,ParameterValue=${PublicSubnetID2} \
    ParameterKey=PrivateSubnetID1,ParameterValue=${PrivateSubnetID1} \
    ParameterKey=PrivateSubnetID2,ParameterValue=${PrivateSubnetID2} \
    ParameterKey=KeyPairName,ParameterValue=${KeyPairName} \
    ParameterKey=InstanceType,ParameterValue=${InstanceType} \
    ParameterKey=PrivilegedPolicyName,ParameterValue=${PrivilegedPolicyName} \
    ParameterKey=GithubToken,ParameterValue=${GithubToken} \
    ParameterKey=Venue,ParameterValue=${Venue} \
  --tags Key=ServiceArea,Value=U-CS


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

