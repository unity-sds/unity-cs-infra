#!/bin/bash

source .env

if [ $# -eq 0 ]
then
    echo "Usage: ./run.sh <aws_saml_profile_name>"
    exit
fi

ACCOUNT_NAME=$1


ROLE_NAME="Unity-CS_Service_Role"
POLICY_LIST=(AmazonEC2ContainerRegistryPowerUser AmazonS3ReadOnlyAccess AmazonSSMManagedInstanceCore CloudWatchAgentServerPolicy DatalakeKinesisPolicy McpToolsAccessPolicy U-CS_Service_Policy U-CS_Service_Policy_Ondemand)
DYNAMIC_POLICY_LIST=(U-CS_Service_Policy U-CS_Service_Policy_Ondemand)


## Delete old SSM parameters
aws ssm delete-parameter --name "/unity/cs/testing/nightly/vpc-id" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/publicsubnet1" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/publicsubnet2" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/privatesubnet1" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/privatesubnet2" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/githubtoken" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/mc_username" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/mc_password" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/slack-web-hook-url" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/venue" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/privilegedpolicyname" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/instancetype" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/testing/nightly/accountname" --profile ${ACCOUNT_NAME}


## Clean up existing roles and policies
## Detach the proper policies from the role
aws iam list-policies --profile ${ACCOUNT_NAME} > policies.list
## Attach the proper policies to the role
for POLICY_NAME in "${POLICY_LIST[@]}"
do
    POLICY_ARN=$(cat policies.list |jq '.Policies[]' |jq 'select(.PolicyName == "'${POLICY_NAME}'")' |jq -r '.Arn')
    echo "Detach role policy $POLICY_ARN from $ROLE_NAME"
    aws iam detach-role-policy --role-name ${ROLE_NAME} --policy-arn ${POLICY_ARN} --profile ${ACCOUNT_NAME}
done


## Delete dynamically created policies
for POLICY_NAME in "${DYNAMIC_POLICY_LIST[@]}"
do
    POLICY_ARN=$(cat policies.list |jq '.Policies[]' |jq 'select(.PolicyName == "'${POLICY_NAME}'")' |jq -r '.Arn')
    echo "Delete Policy $POLICY_ARN"
    aws iam delete-policy --policy-arn ${POLICY_ARN} --profile ${ACCOUNT_NAME}
done

echo "Delete role policy U-CS_Minimum_ECS-Policy from $ROLE_NAME"
aws iam delete-role-policy --role-name ${ROLE_NAME} --policy-name U-CS_Minimum_ECS-Policy --profile ${ACCOUNT_NAME}

## Remove the instance profile
echo "Remove role from instance profile $ROLE_NAME"
aws iam remove-role-from-instance-profile --instance-profile-name ${ROLE_NAME}-instance-profile --role-name ${ROLE_NAME} --profile ${ACCOUNT_NAME}
echo "Delete Instance Profile ${ROLE_NAME}-instance-profile"
aws iam delete-instance-profile --instance-profile-name ${ROLE_NAME}-instance-profile --profile ${ACCOUNT_NAME}

## Finally, delete the role
echo "Delete Role $ROLE_NAME"
aws iam delete-role --role-name ${ROLE_NAME} --profile ${ACCOUNT_NAME}

