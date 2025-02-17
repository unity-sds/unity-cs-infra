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
echo "Checking CloudFormation stack status..." >> nightly_output.txt
INITIAL_STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "${STACK_NAME}" --query 'Stacks[0].StackStatus' --output text 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "Error: Unable to retrieve stack status. The stack ${STACK_NAME} may not exist."
    echo "Error: Unable to retrieve stack status. The stack ${STACK_NAME} may not exist." >> nightly_output.txt

    INITIAL_STACK_STATUS="DOES_NOT_EXIST"
fi

echo "Current stack status: ${INITIAL_STACK_STATUS}"
echo "Current stack status: ${INITIAL_STACK_STATUS}" >> nightly_output.txt

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
    key            = "${PROJECT_NAME}-${VENUE_NAME}-tfstate"
    region         = "us-west-2"
    dynamodb_table = "${PROJECT_NAME}-${VENUE_NAME}-terraform-state"
  }
}
EOF

    echo "Destroying ${PROJECT_NAME}-${VENUE_NAME} Management Console and AWS resources..."
    echo "Destroying ${PROJECT_NAME}-${VENUE_NAME} Management Console and AWS resources..." >> nightly_output.txt
    # Start the timer
    START_TIME=$(date +%s)

    # Initialize Terraform
    echo "Initializing Terraform..."
    if ! terraform init -reconfigure; then
        echo "Error: Could not initialize Terraform for ${PROJECT_NAME}/${VENUE_NAME}."
        echo "Error: Could not initialize Terraform for ${PROJECT_NAME}/${VENUE_NAME}." >> nightly_output.txt
        cd - || exit 1
        rm -rf "name-spaces/${PROJECT_NAME}-${VENUE_NAME}"
        exit 1
    fi

    # Run Terraform Destroy
    echo "Destroying resources..."
    if ! terraform destroy -auto-approve; then
        echo "Error: Could not delete ${PROJECT_NAME}/${VENUE_NAME} AWS resources."
        echo "Error: Could not delete ${PROJECT_NAME}/${VENUE_NAME} AWS resources." >> nightly_output.txt
        cd - || exit 1
        rm -rf "name-spaces/${PROJECT_NAME}-${VENUE_NAME}"
        exit 1
    fi

    # Delete the DynamoDB table only if the initial stack status was CREATE_COMPLETE

    DYNAMODB_TABLE="${PROJECT_NAME}-${VENUE_NAME}-terraform-state"
    echo "Deleting DynamoDB table ${DYNAMODB_TABLE}..."
    echo "Deleting DynamoDB table ${DYNAMODB_TABLE}..." >> nightly_output.txt
    if ! aws dynamodb delete-table --table-name "${DYNAMODB_TABLE}"; then
        echo "Error: Could not delete DynamoDB table ${DYNAMODB_TABLE}."
        exit 1
    fi
    echo "DynamoDB table ${DYNAMODB_TABLE} was deleted successfully"
    echo "DynamoDB table ${DYNAMODB_TABLE} was deleted successfully" >> nightly_output.txt

    # End the timer
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # Clean up
    cd - || exit 1
    rm -rf "name-spaces/${PROJECT_NAME}-${VENUE_NAME}"
    echo "Terraform operations completed. Namespace directory and all Terraform files have been deleted."
    echo "Terraform operations completed. Namespace directory and all Terraform files have been deleted." >> nightly_output.txt
    echo "MC Teardown: Completed in $DURATION seconds"
    echo "MC Teardown: Completed in $DURATION seconds" >> nightly_output.txt
fi

# Delete CloudFormation stack
echo "Destroying cloudformation stack [${STACK_NAME}]..."
echo "Destroying cloudformation stack [${STACK_NAME}]..." >> nightly_output.txt
aws cloudformation delete-stack --stack-name ${STACK_NAME}

STACK_STATUS=""
WAIT_TIME=0
MAX_WAIT_TIME=2400
WAIT_BLOCK=20

while [ -z "$STACK_STATUS" ]
do
    echo "Waiting for Cloudformation Stack Termination..............................[$WAIT_TIME]"
    echo "Waiting for Cloudformation Stack Termination..............................[$WAIT_TIME]" >> nightly_output.txt
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

# Before running destroy_deployment_ssm_params.sh, remove Apache config block

echo "Removing Apache configuration block from S3..."

# Create temporary file for modified config
TEMP_CONFIG="/tmp/unity-cs.conf"

# Get environment from SSM
export ENV_SSM_PARAM="/unity/account/venue"
ENVIRONMENT=$(aws ssm get-parameter --name ${ENV_SSM_PARAM} --query "Parameter.Value" --output text)
echo "Environment from SSM: ${ENVIRONMENT}"

# Use environment in S3 bucket name
S3_BUCKET="ucs-shared-services-apache-config-${ENVIRONMENT}"

# Download the current config
if ! aws s3 cp s3://${S3_BUCKET}/unity-cs.conf $TEMP_CONFIG; then
    echo "Warning: Could not download Apache configuration from S3"
    echo "Warning: Could not download Apache configuration from S3" >> nightly_output.txt
else
    # Remove the configuration block using sed
    START_MARKER="# ---------- BEGIN ${PROJECT_NAME}/${VENUE_NAME} ----------"
    END_MARKER="# ---------- END ${PROJECT_NAME}/${VENUE_NAME} ----------"
    
    # Check if the markers exist in the file
    if grep -q "$START_MARKER" "$TEMP_CONFIG" && grep -q "$END_MARKER" "$TEMP_CONFIG"; then
        # Escape special characters in the markers
        ESCAPED_START=$(echo "$START_MARKER" | sed 's/[]\/$*.^[]/\\&/g')
        ESCAPED_END=$(echo "$END_MARKER" | sed 's/[]\/$*.^[]/\\&/g')
        
        # Use sed to remove everything between and including the markers
        sed -i "/$ESCAPED_START/,/$ESCAPED_END/d" $TEMP_CONFIG

        # Upload the modified config back to S3
        if aws s3 cp $TEMP_CONFIG s3://${S3_BUCKET}/unity-cs.conf; then
            echo "Successfully removed Apache configuration block from S3"
            echo "Successfully removed Apache configuration block from S3" >> nightly_output.txt
        else
            echo "Warning: Failed to upload modified Apache configuration to S3"
            echo "Warning: Failed to upload modified Apache configuration to S3" >> nightly_output.txt
        fi
    else
        echo "No configuration block found for ${PROJECT_NAME}/${VENUE_NAME} - Skipping removal"
        echo "No configuration block found for ${PROJECT_NAME}/${VENUE_NAME} - Skipping removal" >> nightly_output.txt
    fi

    # Clean up
    rm $TEMP_CONFIG
fi

# Run the destroy_deployment_ssm_params.sh script
echo "Running destroy_deployment_ssm_params.sh script..."
./destroy_deployment_ssm_params.sh --project-name "${PROJECT_NAME}" --venue-name "${VENUE_NAME}"

