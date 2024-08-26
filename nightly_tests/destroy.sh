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


# Check if Terraform is installed
if command -v terraform &> /dev/null
then
    echo "Terraform is already installed."
else
    echo "Terraform is not installed. Installing Terraform..."

    
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

    # Install the HashiCorp 
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    # Add the HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Update package and install Terraform
    sudo apt-get update
    sudo apt-get install -y terraform

    echo "Terraform installation completed."
fi

export STACK_NAME="unity-management-console-${PROJECT_NAME}-${VENUE_NAME}"

# Check CloudFormation stack status
echo "Checking CloudFormation stack status..."
INITIAL_STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --query 'Stacks[0].StackStatus' --output text 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Error: Unable to retrieve stack status. The stack ${STACK_NAME} may not exist."
    INITIAL_STACK_STATUS="DOES_NOT_EXIST"
fi

echo "Current stack status: ${INITIAL_STACK_STATUS}"

if [ "${INITIAL_STACK_STATUS}" == "CREATE_COMPLETE" ]; then
    # Create namespace directory
    NAMESPACE_DIR="name-spaces/${PROJECT_NAME}-${VENUE_NAME}"
    mkdir -p "$NAMESPACE_DIR"
    cd "$NAMESPACE_DIR" || exit 1

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
    # Start the timer
    START_TIME=$(date +%s)

    # Initialize Terraform
    echo "Initializing Terraform..."
    if ! terraform init -reconfigure; then
        echo "Error: Could not initialize Terraform for ${PROJECT_NAME}/${VENUE_NAME}."
        cd - || exit 1
        rm -rf "name-spaces/${PROJECT_NAME}-${VENUE_NAME}"
        exit 1
    fi

    # Run Terraform Destroy
    echo "Destroying resources..."
    if ! terraform destroy -auto-approve; then
        echo "Error: Could not delete ${PROJECT_NAME}/${VENUE_NAME} AWS resources."
        cd - || exit 1
        rm -rf "name-spaces/${PROJECT_NAME}-${VENUE_NAME}"
        exit 1
    fi

    # End the timer
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # Clean up
    cd - || exit 1
    rm -rf "name-spaces/${PROJECT_NAME}-${VENUE_NAME}"
    echo "Terraform operations completed. Namespace directory and all Terraform files have been deleted."
    echo "Total duration: $DURATION seconds"
fi

# Delete CloudFormation stack
echo "Destroying cloudformation stack..."
aws cloudformation delete-stack --stack-name ${STACK_NAME}

STACK_STATUS=""
WAIT_TIME=0
MAX_WAIT_TIME=2400
WAIT_BLOCK=20

while [ -z "$STACK_STATUS" ]
do
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
        echo ""
        echo "Stack teardown exceeded ${MAX_WAIT_TIME} seconds - [FAIL]" >> nightly_output.txt
        echo "Stack teardown exceeded ${MAX_WAIT_TIME} seconds - [FAIL]"
        STACK_STATUS="TIMEOUT"
        break
    fi
done

if [ "$STACK_STATUS" == "TERMINATED" ]; then 
    echo "Stack Teardown: Completed in ${WAIT_TIME}s - [PASS]" >> nightly_output.txt
    echo "Stack Teardown: Completed in ${WAIT_TIME}s - [PASS]"
elif [ "$STACK_STATUS" == "TIMEOUT" ]; then
    echo "Stack Teardown: Timed out after ${WAIT_TIME}s - [FAIL]" >> nightly_output.txt
    echo "Stack Teardown: Timed out after ${WAIT_TIME}s - [FAIL]"
else
    echo "Stack Teardown: Failed with unknown status - [FAIL]" >> nightly_output.txt
    echo "Stack Teardown: Failed with unknown status - [FAIL]"
fi

# Run the destroy_deployment_ssm_params.sh script
echo "Running destroy_deployment_ssm_params.sh script..."
./destroy_deployment_ssm_params.sh --project-name "${PROJECT_NAME}" --venue-name "${VENUE_NAME}"

# Delete the DynamoDB table only if the initial stack status was CREATE_COMPLETE
if [ "${INITIAL_STACK_STATUS}" == "CREATE_COMPLETE" ]; then
    DYNAMODB_TABLE="${PROJECT_NAME}-${VENUE_NAME}-terraform-state"
    echo "Deleting DynamoDB table ${DYNAMODB_TABLE}..."
    if ! aws dynamodb delete-table --table-name "${DYNAMODB_TABLE}"; then
        echo "Error: Could not delete DynamoDB table ${DYNAMODB_TABLE}."
        exit 1
    fi
    echo "DynamoDB table ${DYNAMODB_TABLE} was deleted successfully"
fi
