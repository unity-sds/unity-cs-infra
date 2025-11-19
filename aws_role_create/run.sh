#!/bin/bash

source .env

if [ $# -eq 0 ]
then
    echo "Usage: ./run.sh <aws_saml_profile_name>"
    exit
fi

ACCOUNT_NAME=$1




## Create vpc id
VPC_ID=$(aws ec2 describe-vpcs --profile unity-sbg-dev |jq -r '.Vpcs[].VpcId')
echo "Write parameter vpc-id"
aws ssm put-parameter --name "/unity/testing/nightly/vpc-id" --value "$VPC_ID" --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}

## Create subnets
aws ec2 describe-subnets --profile ${ACCOUNT_NAME} |jq -r '.Subnets[].SubnetId' >subnet_ids.txt

while read subnet_id; do
  IS_PRIVATE_A=$(aws ec2 describe-subnets --subnet-ids=$subnet_id --profile ${ACCOUNT_NAME} |grep PrivSubnet01)
  IS_PRIVATE_B=$(aws ec2 describe-subnets --subnet-ids=$subnet_id --profile ${ACCOUNT_NAME} |grep PrivSubnet02)
  IS_PUBLIC_A=$(aws ec2 describe-subnets --subnet-ids=$subnet_id --profile ${ACCOUNT_NAME} |grep PubSubnet01)
  IS_PUBLIC_B=$(aws ec2 describe-subnets --subnet-ids=$subnet_id --profile ${ACCOUNT_NAME} |grep PubSubnet02)

  if [[ ! -z "$IS_PRIVATE_A" ]]; then
    echo "Write parameter privatesubnet1"
    aws ssm put-parameter --name "/unity/testing/nightly/privatesubnet1" --value "$subnet_id" --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
  elif [[ ! -z "$IS_PRIVATE_B" ]]; then
    echo "Write parameter privatesubnet2"
    aws ssm put-parameter --name "/unity/testing/nightly/privatesubnet2" --value "$subnet_id" --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
  elif [[ ! -z "$IS_PUBLIC_A" ]]; then
    echo "Write parameter publicsubnet1"
    aws ssm put-parameter --name "/unity/testing/nightly/publicsubnet1" --value "$subnet_id" --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
  elif [[ ! -z "$IS_PUBLIC_B" ]]; then
    echo "Write parameter publicsubnet2"
    aws ssm put-parameter --name "/unity/testing/nightly/publicsubnet2" --value "$subnet_id" --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
  fi
done <subnet_ids.txt

## Read these from from .env file
echo "Write parameter githubtoken"
aws ssm put-parameter --name "/unity/testing/nightly/githubtoken"          --value "$GITHUB_TOKEN"           --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
echo "Write parameter mc_username"
aws ssm put-parameter --name "/unity/testing/nightly/mc_username"          --value "$MC_USERNAME"            --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
echo "Write parameter mc_password"
aws ssm put-parameter --name "/unity/testing/nightly/mc_password"          --value "$MC_PASSWORD"            --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
echo "Write parameter slack-web-hook-url"
aws ssm put-parameter --name "/unity/ci/slack-web-hook-url"                --value "$SLACK_WEBHOOK_URL"      --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
echo "Write parameter venue"
aws ssm put-parameter --name "/unity/testing/nightly/venue"                --value "$VENUE"                  --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
echo "Write parameter privilegedpolicyname"
aws ssm put-parameter --name "/unity/testing/nightly/privilegedpolicyname" --value "$PRIVILEGED_POLICY_NAME" --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
echo "Write parameter instancetype"
aws ssm put-parameter --name "/unity/testing/nightly/instancetype"         --value "$INSTANCE_TYPE"          --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
echo "Write parameter accountname"
aws ssm put-parameter --name "/unity/testing/nightly/accountname"         --value "$ACCOUNT_NAME"            --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}

#exit


ROLE_NAME="Unity-CS_Service_Role"
POLICY_LIST=(AmazonEC2ContainerRegistryPowerUser AmazonS3ReadOnlyAccess AmazonSSMManagedInstanceCore CloudWatchAgentServerPolicy DatalakeKinesisPolicy McpToolsAccessPolicy U-CS_Service_Policy U-CS_Service_Policy_Ondemand)
DYNAMIC_POLICY_LIST=(U-CS_Service_Policy U-CS_Service_Policy_Ondemand)






## Set the SSM parameters
## VPC ID
VPC_ID=$(aws ec2 describe-vpcs --vpc-ids --profile unity-cm |grep VpcId |sed 's/^.*: "//g'|sed 's/",//g')
echo "VPC_ID: $VPC_ID"
#exit

## Get the account number
aws sts get-caller-identity --profile ${ACCOUNT_NAME} > identity.txt
ACCOUNT_NUMBER=$(cat identity.txt|jq -r '.Account')
echo "Account Number: $ACCOUNT_NUMBER"

## Create the role to act as a service role
#aws iam create-role --role-name U-CS-Service-Role-Test --permission-boundary arn:aws:iam::865428270474:policy/mcp-tenantOperator-AMI-APIG --output role.out
aws iam create-role --role-name ${ROLE_NAME} --permissions-boundary arn:aws:iam::${ACCOUNT_NUMBER}:policy/zsmce-tenantOperator-AMI-APIG --assume-role-policy-document file://U-CS_Service_Role_Trust_Policy.json --profile ${ACCOUNT_NAME} > role.txt
cat role.txt
ROLE_ARN=$(cat role.txt|jq -r '.Role.Arn')
echo "Role ARN: $ROLE_ARN"


## Add the inline policy
aws iam put-role-policy --role-name ${ROLE_NAME} --policy-name U-CS_Minimum_ECS-Policy --policy-document file://Minimum_ECS_Policy.json --profile ${ACCOUNT_NAME} >output.txt
cat output.txt

## U-CS Managed (These need to be created beforehand)
# U-CS_Service_Policy
aws iam create-policy --policy-name U-CS_Service_Policy --policy-document file://U-CS_Service_Policy.json --description "Policy containing permissions for automated U-CS Operations" --tags Key=ServiceArea,Value=U-CS --profile ${ACCOUNT_NAME} > output.txt
cat output.txt
# U-CS_Service_Policy_Ondemand
aws iam create-policy --policy-name U-CS_Service_Policy_Ondemand --policy-document file://U-CS_Service_Policy_Ondemand.json --description "Policy containing additional permissions for automated U-CS Operations" --tags Key=ServiceArea,Value=U-CS --profile ${ACCOUNT_NAME} > output.txt
cat output.txt

## Get the arns for the policies that we need attached
aws iam list-policies --profile ${ACCOUNT_NAME} > policies.list


## Attach the proper policies to the role
for POLICY_NAME in "${POLICY_LIST[@]}"
do
    POLICY_ARN=$(cat policies.list |jq '.Policies[]' |jq 'select(.PolicyName == "'${POLICY_NAME}'")' |jq -r '.Arn')
    echo "POLICY_ARN: $POLICY_ARN"
    aws iam attach-role-policy --role-name ${ROLE_NAME} --policy-arn ${POLICY_ARN} --profile ${ACCOUNT_NAME}
done


## Attach 
aws iam create-instance-profile --instance-profile-name ${ROLE_NAME}-instance-profile --profile ${ACCOUNT_NAME}
aws iam add-role-to-instance-profile --instance-profile-name ${ROLE_NAME}-instance-profile --role-name ${ROLE_NAME} --profile ${ACCOUNT_NAME}
