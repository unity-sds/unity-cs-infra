#!/usr/bin/bash

# 
PROJECT_NAME=""
VENUE_NAME=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 --project-name <PROJECT_NAME> --venue-name <VENUE_NAME>"
    exit 1
}

#
# It's mandatory to speciy a valid command arguments
#
if [[ $# -ne 4 ]]; then
  usage
fi

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --venue-name)
            VENUE_NAME="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Check if mandatory options are provided
if [[ -z $PROJECT_NAME ]]; then
    usage
fi
if [[ -z $VENUE_NAME ]]; then
    usage
fi

echo "destroy.sh :: PROJECT_NAME: ${PROJECT_NAME}"
echo "destroy.sh :: VENUE_NAME: ${VENUE_NAME}"

source NIGHTLY.ENV

export STACK_NAME="unity-management-console-${PROJECT_NAME}-${VENUE_NAME}"
# Create Terraform configuration file
CONFIG_FILE="${PROJECT_NAME}-${VENUE_NAME}.tf"

cat <<EOF > "${CONFIG_FILE}"
terraform {
  backend "s3" {
    bucket         = "unity-${PROJECT_NAME}-${VENUE_NAME}-bucket"
    key            = "default"
    region         = "us-west-2"
    dynamodb_table = "${PROJECT_NAME}-${VENUE_NAME}-terraform-state"
  }
}
EOF

echo "Destroying ${PROJECT_NAME}-${VENUE_NAME} Management Console and AWS resources..."

# Initialize Terraform
echo "Initializing Terraform..."
if ! terraform init -reconfigure; then
    echo "Error: Could not initialize Terraform for ${PROJECT_NAME}/${VENUE_NAME}."
    exit 1
fi

# Run Terraform Destroy
echo "Destroying resources..."
if ! terraform destroy -auto-approve; then
    echo "Error: Could not delete ${PROJECT_NAME}/${VENUE_NAME} AWS resources."
    exit 1
fi

# Delete the Terraform configuration file
rm -f "${CONFIG_FILE}"
rm -f .terraform.lock.hcl
rm -rf .terraform/
echo "Terraform configuration file ${CONFIG_FILE} has been deleted."


echo "${PROJECT_NAME}-${VENUE_NAME} Management Console and AWS resources destruction complete"


echo "Destroying cloudformation stack"

aws cloudformation delete-stack --stack-name ${STACK_NAME}

STACK_STATUS=""

WAIT_TIME=0
MAX_WAIT_TIME=2400
WAIT_BLOCK=20

while [ -z "$STACK_STATUS" ]
do

    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Waiting for Cloudformation Stack Termination..............................[$WAIT_TIME]"

    aws cloudformation describe-stacks --stack-name ${STACK_NAME} > status.txt
    STACK_STATUS=""
    if [ -s status.txt ]
    then
        STACK_STATUS=""
    else
        STACK_STATUS="TERMINATED"
    fi

    sleep $WAIT_BLOCK
    WAIT_TIME=$(($WAIT_BLOCK + $WAIT_TIME))
    if [ "$WAIT_TIME" -gt "$MAX_WAIT_TIME" ] 
    then
        #echo"--------------------------------------------------------------------------[PASS]" 
        echo ""
        echo "Stack teardown exceeded ${MAX_WAIT_TIME} seconds - [FAIL]" >> nightly_output.txt
        echo "Stack teardown exceeded ${MAX_WAIT_TIME} seconds - [FAIL]"

        exit
    fi
done

if [ "$STACK_STATUS" == "TERMINATED" ]
then 
    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Stack Teardown: Completed in ${WAIT_TIME}s - [PASS]" >> nightly_output.txt
    echo "Stack Teardown: Completed in ${WAIT_TIME}s - [PASS]"

fi

./destroy_deployment_ssm_params.sh --project-name "${PROJECT_NAME}" --venue-name "${VENUE_NAME}"

# Delete the DynamoDB table
DYNAMODB_TABLE="${PROJECT_NAME}-${VENUE_NAME}-terraform-state"
echo "Deleting DynamoDB table ${DYNAMODB_TABLE}..."
if ! aws dynamodb delete-table --table-name "${DYNAMODB_TABLE}"; then
    echo "Error: Could not delete DynamoDB table ${DYNAMODB_TABLE}."
    exit 1
fi

echo "DynamoDB table ${DYNAMODB_TABLE} was deleted successfully"
