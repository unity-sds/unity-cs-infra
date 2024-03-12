#!/bin/bash

ROLE_NAME="Unity-CS_Service_Role"
POLICY_LIST=(AmazonEC2ContainerRegistryPowerUser AmazonS3ReadOnlyAccess AmazonSSMManagedInstanceCore CloudWatchAgentServerPolicy DatalakeKinesisPolicy McpToolsAccessPolicy U-CS_Service_Policy U-CS_Service_Policy_Ondemand)
DYNAMIC_POLICY_LIST=(U-CS_Service_Policy U-CS_Service_Policy_Ondemand)

## Get the account number
aws sts get-caller-identity > identity.txt
ACCOUNT_NUMBER=$(cat identity.txt|jq -r '.Account')
echo "Account Number: $ACCOUNT_NUMBER"

## Create the role to act as a service role
#aws iam create-role --role-name U-CS-Service-Role-Test --permission-boundary arn:aws:iam::865428270474:policy/mcp-tenantOperator-AMI-APIG --output role.out
echo "Creating role ${ROLE_NAME} ..."
aws iam create-role \
    --role-name ${ROLE_NAME} \
    --permissions-boundary arn:aws:iam::${ACCOUNT_NUMBER}:policy/mcp-tenantOperator-AMI-APIG \
    --assume-role-policy-document file://U-CS_Service_Role_Trust_Policy.json  > role.txt
cat role.txt
ROLE_ARN=$(cat role.txt|jq -r '.Role.Arn')
echo "Role ARN: $ROLE_ARN"

## Add the inline policy
aws iam put-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-name U-CS_Minimum_ECS-Policy \
    --policy-document file://Minimum_ECS_Policy.json >output.txt
cat output.txt

## U-CS Managed (These need to be created beforehand)
# U-CS_Service_Policy
aws iam create-policy \
    --policy-name U-CS_Service_Policy \
    --policy-document file://U-CS_Service_Policy.json \
    --description "Policy containing permissions for automated U-CS Operations" \
    --tags Key=ServiceArea,Value=U-CS > output.txt
cat output.txt

# U-CS_Service_Policy_Ondemand
aws iam create-policy \
    --policy-name U-CS_Service_Policy_Ondemand \
    --policy-document file://U-CS_Service_Policy_Ondemand.json \
    --description "Policy containing additional permissions for automated U-CS Operations" \
    --tags Key=ServiceArea,Value=U-CS > output.txt
cat output.txt

## Get the arns for the policies that we need attached
aws iam list-policies > policies.list


## Attach the proper policies to the role
for POLICY_NAME in "${POLICY_LIST[@]}"
do
    POLICY_ARN=$(cat policies.list |jq '.Policies[]' |jq 'select(.PolicyName == "'${POLICY_NAME}'")' |jq -r '.Arn')
    echo "POLICY_ARN: $POLICY_ARN"
    aws iam attach-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-arn ${POLICY_ARN}
done


## Attach 
aws iam create-instance-profile --instance-profile-name ${ROLE_NAME}-instance-profile
aws iam add-role-to-instance-profile \
    --instance-profile-name ${ROLE_NAME}-instance-profile \
    --role-name ${ROLE_NAME}
