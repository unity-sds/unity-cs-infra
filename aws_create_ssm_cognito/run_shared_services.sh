#!/bin/bash

source .env

if [ $# -eq 0 ]
then
    echo "Usage: ./run.sh <aws_saml_profile_name>"
    exit
fi

ACCOUNT_NAME=$1

aws ssm put-parameter --name "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-client-id-list"   --value "$cognito_client_id_list_shared"   --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
aws ssm put-parameter --name "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-user-pool-id"     --value "$cognito_user_pool_id_shared"     --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
aws ssm put-parameter --name "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-user-groups-list" --value "$cognito_user_groups_list_shared" --type String --tags "Key=ServiceArea,Value=U-CS" --profile ${ACCOUNT_NAME}
