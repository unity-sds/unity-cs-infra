#!/bin/bash

STACK_NAME=""
PROJECT_NAME=""
VENUE_NAME=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 --stack-name <cloudformation_stack_name> --project-name <PROJECT_NAME>"
    exit 1
}

#
# It's mandatory to speciy a valid command arguments
#
if [[ $# -ne 2 ]]; then
  usage
fi

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

#
# Does a deployment already exist for this project/venue?
# If so, then don't continue with this deployment.  
# Warn the user, and bail out.
#
echo "Checking for existing deployment for (project=${PROJECT_NAME}, venue=${VENUE_NAME}) ..."
aws ssm get-parameter --name "/unity/deployment/${PROJECT_NAME}/${VENUE_NAME}/status" 2>ssm_lookup.txt
if [[ `grep "ParameterNotFound" ssm_lookup.txt | wc -l` == "1" ]]; then
    echo "Existing deployment not found.  Continuing with deployment..."
else
    echo "ERROR: A deployment appears to already exist for project=${PROJECT_NAME}, venue=${VENUE_NAME}."
    echo "       Please cleanup the resources for this deployment, before continuing!"
    exit 1
fi

# /unity/deployment/<PROJECT_NAME>/<VENUE_NAME>/*
# /unity/deployment/eurc/dev/proj-name
# /unity/deployment/eurc/dev/venue-name
# /unity/deployment/eurc/dev/management-console-alb-url
# /unity/deployment/eurc/dev/dashboard-url
# /unity/deployment/eurc/dev/sps/ui-url
# /unity/deployment/eurc/dev/sps/maxNumNodes
# /unity/cs/network/vpc_id

#
# Create the SSM parameters required by this deployment
#
source ./set_deployment_ssm_params.sh --project-name "${PROJECT_NAME}"

export SSH_KEY="~/.ssh/ucs-nightly.pem"
export SSM_VPC_ID="/unity/testing/nightly/vpc-id"
export SSM_KEYPAIR_NAME="/unity/testing/nightly/keypairname"
export SSM_INSTANCE_TYPE="/unity/testing/nightly/instancetype"
export SSM_PRIVILEGED_POLICY="/unity/testing/nightly/privilegedpolicyname"
export SSM_GITHUB_TOKEN="/unity/testing/nightly/githubtoken"
export SSM_ACCOUNT_NAME="/unity/testing/nightly/accountname"

InstanceType=$(aws ssm get-parameter         --name ${SSM_INSTANCE_TYPE}     |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PrivilegedPolicyName=$(aws ssm get-parameter --name ${SSM_PRIVILEGED_POLICY} |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
GithubToken=$(aws ssm get-parameter          --name ${SSM_GITHUB_TOKEN}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
ACCOUNT_NAME=$(aws ssm get-parameter         --name ${SSM_ACCOUNT_NAME}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')


aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-body file://template.yml \
  --capabilities CAPABILITY_IAM \
  --parameters \
    ParameterKey=VPCID,ParameterValue=${VPC_ID_VAL} \
    ParameterKey=PublicSubnetID1,ParameterValue=${PUB_SUBNET_1_VAL} \
    ParameterKey=PublicSubnetID2,ParameterValue=${PUB_SUBNET_2_VAL} \
    ParameterKey=PrivateSubnetID1,ParameterValue=${PRIV_SUBNET_1_VAL} \
    ParameterKey=PrivateSubnetID2,ParameterValue=${PRIV_SUBNET_2_VAL} \
    ParameterKey=InstanceType,ParameterValue=${InstanceType} \
    ParameterKey=PrivilegedPolicyName,ParameterValue=${PrivilegedPolicyName} \
    ParameterKey=GithubToken,ParameterValue=${GithubToken} \
    ParameterKey=Venue,ParameterValue=${VENUE_NAME} \
  --tags Key=ServiceArea,Value=U-CS


echo "Nightly Test in the $ACCOUNT_NAME account" >> nightly_output.txt
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

