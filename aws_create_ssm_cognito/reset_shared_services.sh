#!/bin/bash

source .env

if [ $# -eq 0 ]
then
    echo "Usage: ./run.sh <aws_saml_profile_name>"
    exit
fi

ACCOUNT_NAME=$1

## Delete old SSM parameters
aws ssm delete-parameter --name "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-client-id-list" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-user-pool-id" --profile ${ACCOUNT_NAME}
aws ssm delete-parameter --name "/unity/cs/routing/shared-api-gateway/cs-lambda-authorizer-cognito-user-groups-list" --profile ${ACCOUNT_NAME}
