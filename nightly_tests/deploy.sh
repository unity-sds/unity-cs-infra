#!/bin/bash

STACK_NAME=""
PROJECT_NAME=""
VENUE_NAME=""
MC_VERSION="latest"
MC_SHA=""
CONFIG_FILE=""
LATEST=false
UNITY_CS_MONITORING_LAMBDA_VERSION=""
UNITY_APIGATEWAY_VERSION=""
UNITY_PROXY_VERSION=""
UNITY_UI_VERSION=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 --stack-name <cloudformation_stack_name> --project-name <PROJECT_NAME> --venue-name <VENUE_NAME> [--mc-version <MC_VERSION>] [--mc-sha <MC_SHA>] [--config-file <CONFIG_FILE>] [--latest] [--unity-cs-monitoring-lambda-version <VERSION>] [--unity-apigateway-version <VERSION>] [--unity-proxy-version <VERSION>] [--unity-ui-version <VERSION>]"
    exit 1
}

#
# It's mandatory to specify a valid command arguments
#
# if [[ $# -ne 6 ]]; then
#  usage
# fi

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --venue-name)
            VENUE_NAME="$2"
            shift 2
            ;;            
        --mc-version)
            MC_VERSION="$2"
            shift 2
            ;;
        --mc-sha)
            MC_SHA="$2"
            shift 2
            ;;
        --config-file)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --latest)
            LATEST=true
            shift
            ;;
        --unity-cs-monitoring-lambda-version)
            UNITY_CS_MONITORING_LAMBDA_VERSION="$2"
            shift 2
            ;;
        --unity-apigateway-version)
            UNITY_APIGATEWAY_VERSION="$2"
            shift 2
            ;;
        --unity-proxy-version)
            UNITY_PROXY_VERSION="$2"
            shift 2
            ;;
        --unity-ui-version)
            UNITY_UI_VERSION="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Check if mandatory options are provided
if [[ -z $STACK_NAME ]]; then
    usage
fi
if [[ -z $PROJECT_NAME ]]; then
    usage
fi
if [[ -z $VENUE_NAME ]]; then
    usage
fi

echo "deploy.sh :: STACK_NAME: ${STACK_NAME}"
echo "deploy.sh :: PROJECT_NAME: ${PROJECT_NAME}"
echo "deploy.sh :: VENUE_NAME: ${VENUE_NAME}"
echo "deploy.sh :: MC_SHA: ${MC_SHA}"

#
# Create the SSM parameters required by this deployment
#
source ./set_deployment_ssm_params.sh --project-name "${PROJECT_NAME}" --venue-name "${VENUE_NAME}"
echo "deploying INSTANCE TYPE: ${MC_INSTANCETYPE_VAL} ..."

echo "Deploying Cloudformation stack..." >> nightly_output.txt
echo "Deploying Cloudformation stack..."

# Function to parse and process config file
process_config_file() {
    if [ -f "$1" ]; then
        # Extract ManagementConsole values if present
        if yq eval '.ManagementConsole' "$1" >/dev/null 2>&1; then
            local mc_release=$(yq eval '.ManagementConsole.release' "$1")
            local mc_sha=$(yq eval '.ManagementConsole.sha' "$1")
            
            # Update MC_VERSION only if --latest is not set and no CLI override
            if [ "$LATEST" = false ] && [ -n "$mc_release" ] && [ "$MC_VERSION" = "latest" ]; then
                MC_VERSION="$mc_release"
            fi
            if [ -n "$mc_sha" ] && [ -z "$MC_SHA" ]; then
                MC_SHA="$mc_sha"
            fi
        fi

        # Force MC_VERSION to "latest" if --latest flag is set
        if [ "$LATEST" = true ]; then
            MC_VERSION="latest"
        fi

        # Process MarketplaceItems
        if [ "$LATEST" = true ]; then
            # Set all versions to "latest" if --latest flag is present
            yq eval 'del(.ManagementConsole) | .MarketplaceItems[].version = "latest"' "$1"
        else
            # Just return the MarketplaceItems section without ManagementConsole
            yq eval 'del(.ManagementConsole) | .MarketplaceItems' "$1"
        fi
    else
        echo "[]"
    fi
}

# Read and process the config file content
config_content=$(process_config_file "$CONFIG_FILE")

# Log the MC version and SHA being used
echo "deploy.sh :: Using MC_VERSION: ${MC_VERSION}"
[ -n "$MC_SHA" ] && echo "deploy.sh :: Using MC_SHA: ${MC_SHA}"

# Output the marketplace items table to both console and nightly_output.txt
{
    echo "-----------------------------------------"
    echo "Items that will auto-deploy on bootstrap:"
    echo "Marketplace Item                | Version"
    echo "--------------------------------+--------"
    echo "$config_content" | grep -E '^\s*-' | sed -E 's/^\s*-\s*name:\s*(.*)/\1/' | while read -r line; do
        name=$(echo "$line" | cut -d' ' -f1)
        version=$(echo "$config_content" | grep -A1 "name: $name" | grep 'version:' | sed -E 's/^\s*version:\s*//')
        printf "%-31s | %s\n" "$name" "$version"
    done
} | tee -a nightly_output.txt

# Escape any special characters in the config content
escaped_config_content=$(echo "$config_content" | sed 's/"/\\"/g')



# Modify the CloudFormation create-stack command
aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-body file://../cloudformation-template/unity-mc.main.template.yaml \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=VPCID,ParameterValue=${VPC_ID_VAL} \
    ParameterKey=PublicSubnetID1,ParameterValue=${PUB_SUBNET_1_VAL} \
    ParameterKey=PublicSubnetID2,ParameterValue=${PUB_SUBNET_2_VAL} \
    ParameterKey=PrivateSubnetID1,ParameterValue=${PRIV_SUBNET_1_VAL} \
    ParameterKey=PrivateSubnetID2,ParameterValue=${PRIV_SUBNET_2_VAL} \
    ParameterKey=InstanceType,ParameterValue=${MC_INSTANCETYPE_VAL} \
    ParameterKey=PrivilegedPolicyName,ParameterValue=${CS_PRIVILEGED_POLICY_NAME_VAL} \
    ParameterKey=GithubToken,ParameterValue=${GITHUB_TOKEN_VAL} \
    ParameterKey=Project,ParameterValue=${PROJECT_NAME} \
    ParameterKey=Venue,ParameterValue=${VENUE_NAME} \
    ParameterKey=MCVersion,ParameterValue=${MC_VERSION} \
    ParameterKey=MCSha,ParameterValue=${MC_SHA} \
    ParameterKey=MarketplaceItems,ParameterValue="${escaped_config_content}" \
  --tags Key=ServiceArea,Value=U-CS


echo "Nightly Test in the (TODO FIXME) account" >> nightly_output.txt
echo "STACK_NAME=$STACK_NAME">NIGHTLY.ENV

#echo"--------------------------------------------------------------------------[PASS]"
echo "Stack Name: [$STACK_NAME]" >> nightly_output.txt
echo "Stack Name: [$STACK_NAME]"


## Wait for startup
STACK_STATUS=""

WAIT_TIME=0
MAX_WAIT_TIME=2400
WAIT_BLOCK=20

while [ -z "$STACK_STATUS" ]
do
    #echo "Checking Stack Creation [${STACK_NAME}] Status after ${WAIT_TIME} seconds..." >> nightly_output.txt
    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Waiting for Cloudformation Stack..........................................[$WAIT_TIME]"

    aws cloudformation describe-stacks --stack-name ${STACK_NAME} > status.txt
    STACK_STATUS=$(cat status.txt |grep '"StackStatus": \"CREATE_COMPLETE\"')
    sleep $WAIT_BLOCK
    WAIT_TIME=$(($WAIT_BLOCK + $WAIT_TIME))
    if [ "$WAIT_TIME" -gt "$MAX_WAIT_TIME" ] 
    then
        #echo"--------------------------------------------------------------------------[PASS]" 
        echo "Cloudformation Stack creation exceeded ${MAX_WAIT_TIME} seconds - [FAIL]" >> nightly_output.txt
        echo "Cloudformation Stack creation exceeded ${MAX_WAIT_TIME} seconds - [FAIL]"
        exit
    fi
done

STACK_STATUS=$(echo "${STACK_STATUS}" |sed 's/^.*: "//' |sed 's/".*//')

#echo "Final Stack Status: ${STACK_STATUS}" >> nightly_output.txt
#echo "Final Stack Status: ${STACK_STATUS}"

#echo"--------------------------------------------------------------------------[PASS]" 
echo "Stack Status (Final): [$STACK_STATUS]" >> nightly_output.txt
echo "Stack Status (Final): [$STACK_STATUS]"


if [ ! -z "$STACK_STATUS" ]
then 
    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Stack Creation Time: [${WAIT_TIME} seconds] - PASS" >> nightly_output.txt
    echo "Stack Creation Time: [${WAIT_TIME} seconds] - PASS"
fi

## This is where some stuff should go

## Get the information needed to connect to the new instance
#aws ec2 describe-instances --instance-id $INSTANCE_ID > status.txt
#IP_ADDRESS=$(grep PrivateIpAddress status.txt |sed 's/^.*: "//' | sed 's/".*$//' |head -n 1)
#echo "IP_ADDRESS=$IP_ADDRESS">>NIGHTLY.ENV

#IP_ADDRESS_PUBLIC=$(grep PublicIpAddress status.txt |sed 's/^.*: "//' | sed 's/".*$//' |head -n 1)
#echo "IP_ADDRESS_PUBLIC=$IP_ADDRESS_PUBLIC">>NIGHTLY.ENV

