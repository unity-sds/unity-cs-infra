#!/bin/bash

# This is used to automate the MPC short term key accessing issue.
# It is based on what is documented here:
# https://caas.gsfc.nasa.gov/display/GSD1/Using+the+Kion+%28Formerly+CloudTamer%29+API+to+generate+AWS+Keys
# I use this script as follows:
# eval $(mcp_keys.sh)
# You need to edit it and add your Kion application key.
# The eval is because the script spits out the variables you need so you can just eval them to bring them into bash instead of copying and pasting.
# Note this script requires the jq tool installed to parse the API response.
# I haven't done this yet, but another idea might be to have the script write to the .aws/credentials file then run the script every hour in a cron job

if [[ -z ${UNITY_CLOUDTAMER_API_URL} ]]; then
  echo "You must have a UNITY_CLOUDTAMER_API_URL environment variable set"
  exit 1
fi

if [[ -z ${UNITY_CLOUDTAMER_API_KEY} ]]; then
  echo "You must have a UNITY_CLOUDTAMER_API_KEY environment variable set"
  exit 1
fi

if [[ -z ${UNITY_CLOUDTAMER_ROLE} ]]; then
  echo "You must have a UNITY_CLOUDTAMER_ROLE environment variable set"
  exit 1
fi


if [ $# -ne 1 ]; then
        echo "Please specify the MCP account/venue (dev or test)"
		exit 1
fi

ACCOUNT_NAME=$1
if [[ $ACCOUNT_NAME == "dev" ]]
then
    if [[ -z ${UNITY_DEV_AWS_ACCOUNT_ID} ]]; then
      echo "You must have a UNITY_DEV_AWS_ACCOUNT_ID environment variable set"
      exit 1
    fi
    AWS_ACCOUNT_ID="${UNITY_DEV_AWS_ACCOUNT_ID}"
elif [[ $ACCOUNT_NAME == "test" ]]
then
    if [[ -z ${UNITY_TEST_AWS_ACCOUNT_ID} ]]; then
          echo "You must have a UNITY_TEST_AWS_ACCOUNT_ID environment variable set"
          exit 1
        fi
        AWS_ACCOUNT_ID="${UNITY_TEST_AWS_ACCOUNT_ID}"
else
    echo "Invalid MCP account name"
    exit 1
fi

response=$(
    curl -s \
	-XPOST \
        -H "accept: application/json" \
        -H "Authorization: Bearer ${UNITY_CLOUDTAMER_API_KEY}" \
        -H "Content-Type: application/json" \
        "${UNITY_CLOUDTAMER_API_URL}/temporary-credentials" \
        -d "{\"account_number\": \"$AWS_ACCOUNT_ID\",\"iam_role_name\": \"$UNITY_CLOUDTAMER_ROLE\"}"
)

access_key_id=$(echo $response | jq -r .data.access_key)
secret_access_key=$(echo $response | jq -r .data.secret_access_key)
session_token=$(echo $response | jq -r .data.session_token)

# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html
expiration=$(date -v +30M -u +"%Y-%m-%dT%H:%M:%SZ")
printf '{"Version":1,"AccessKeyId":"%s","SecretAccessKey":"%s","SessionToken":"%s","Expiration":"%s"}\n' "$access_key_id" "$secret_access_key" "$session_token" "$expiration"
