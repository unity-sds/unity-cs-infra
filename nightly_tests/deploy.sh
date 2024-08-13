#!/bin/bash

STACK_NAME=""
PROJECT_NAME=""
VENUE_NAME=""
MC_VERSION="latest"
BUCKET_LIFECYCLE_IN_DAYS="7"

# Function to display usage instructions
usage() {
    echo "Usage: $0 --stack-name <cloudformation_stack_name> --project-name <PROJECT_NAME> --venue-name <VENUE_NAME> [--mc-version <MC_VERSION>] [--bucket-lifecycle <BUCKET_LIFECYCLE_IN_DAYS>]"
    exit 1
}

#
# It's mandatory to speciy a valid command arguments
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
        --bucket-lifecycle)
            BUCKET_LIFECYCLE_IN_DAYS="$2"
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
echo "deploy.sh :: BUCKET_LIFECYCLE_IN_DAYS: ${BUCKET_LIFECYCLE_IN_DAYS}"

#
# Create the SSM parameters required by this deployment
#
source ./set_deployment_ssm_params.sh --project-name "${PROJECT_NAME}" --venue-name "${VENUE_NAME}" --bucket-lifecycle "${BUCKET_LIFECYCLE_IN_DAYS}"
echo "deploying INSTANCE TYPE: ${MC_INSTANCETYPE_VAL} ..."

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

