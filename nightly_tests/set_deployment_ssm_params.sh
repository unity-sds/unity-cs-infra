#!/bin/bash

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

echo "set_deployment_ssm_params.sh :: PROJECT_NAME: ${PROJECT_NAME}"
echo "set_deployment_ssm_params.sh :: VENUE_NAME: ${VENUE_NAME}"

#
# Sub-routine to gracefully delete a SSM parameter
#
delete_ssm_param() {
    local key=$1
    echo "Deleting SSM parameter: ${key} ..."
    aws ssm get-parameter --name "$key" 2>ssm_lookup.txt
    if [[ `grep "ParameterNotFound" ssm_lookup.txt | wc -l` == "1" ]]; then
        echo "SSM param ${key} not found.  Not attempting a delete."
    else
        aws ssm delete-parameter --name "${key}" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "ERROR: SSM delete failed for $key"
        fi
    fi
}

#
# Sub-routine to create a SSM parameter, and tag it
#
create_ssm_param() {
    local key=$1
    local value=$2
    local capability=$3
    local capVersion=$4
    local component=$5
    local name=$6
echo "Creating SSM parameter : ${key} = ${value} ..."
    aws ssm put-parameter --name "${key}" --value "${value}" --type String \
    --tags \
    "Key=Venue,Value=${VENUE_NAME}" \
    "Key=ServiceArea,Value=cs" \
    "Key=Capability,Value=${capability}" \
    "Key=CapVersion,Value=${capVersion}" \
    "Key=Component,Value=${component}" \
    "Key=Name,Value=${name}" \
    "Key=Proj,Value=${PROJECT_NAME}" \
    "Key=CreatedBy,Value=cs" \
    "Key=Env,Value=${VENUE_NAME}" \
    "Key=Stack,Value=${component}" 2>/dev/null
    # TODO: Is there a SSM Description field (to add above)?
    if [ $? -ne 0 ]; then
        echo "ERROR: SSM create failed for $key"
    fi
}

#
#
#
refresh_ssm_param() {
    local key=$1
    local value=$2
    local capability=$3
    local capVersion=$4
    local component=$5
    local name=$6
    delete_ssm_param "${key}"
    create_ssm_param "${key}" "${value}" "${capability}" "${capVersion}" "${component}" "${name}"
}

#
# Create SSM:
# /unity/deployment/<PROJECT_NAME>/<VENUE_NAME>
#
DEPLOYMENT_STATUS_SSM="/unity/deployment/${PROJECT_NAME}/${VENUE_NAME}/status"
DEPLOYMENT_STATUS_VAL="deploying"
refresh_ssm_param "${DEPLOYMENT_STATUS_SSM}" "${DEPLOYMENT_STATUS_VAL}" "management" "todo" "console" "${PROJECT_NAME}-${VENUE_NAME}-cs-management-deploymentStatusSsm"

#
# Create SSM:
# /unity/cs/account/network/vpc_id
#
VPC_ID_SSM="/unity/cs/account/network/vpc_id"
VPC_ID_VAL=$(aws ec2 describe-vpcs |jq -r '.Vpcs[].VpcId')
refresh_ssm_param "${VPC_ID_SSM}" "${VPC_ID_VAL}" "networking" "na" "vpc" "unity-all-cs-networking-vpcIdSsm"

#
# Create SSM:
# /unity/cs/account/network/subnet_list
#
SUBNET_LIST_SSM="/unity/cs/account/network/subnet_list"
SUBNET_LIST_VAL=$(./get_subnet_list_json.sh)
delete_ssm_param "${SUBNET_LIST_SSM}"
create_ssm_param "${SUBNET_LIST_SSM}" "${SUBNET_LIST_VAL}" "networking" "na" "vpc" "unity-all-cs-networking-subnetListSsm"

#
# Create SSM:
# /unity/cs/account/network/publicsubnet1
#
PUB_SUBNET_1_SSM="/unity/cs/account/network/publicsubnet1"
PUB_SUBNET_1_VAL=$(echo "${SUBNET_LIST_VAL}" | jq -r '.public[0]')
refresh_ssm_param "${PUB_SUBNET_1_SSM}" "${PUB_SUBNET_1_VAL}" "networking" "na" "vpc" "unity-all-cs-networking-publicSubnet1Ssm"

#
# Create SSM:
# /unity/cs/account/network/publicsubnet2
#
PUB_SUBNET_2_SSM="/unity/cs/account/network/publicsubnet2"
PUB_SUBNET_2_VAL=$(echo "${SUBNET_LIST_VAL}" | jq -r '.public[1]')
refresh_ssm_param "${PUB_SUBNET_2_SSM}" "${PUB_SUBNET_2_VAL}" "networking" "na" "vpc" "unity-all-cs-networking-publicSubnet2Ssm"

#
# Create SSM:
# /unity/cs/account/network/privatesubnet1
#
PRIV_SUBNET_1_SSM="/unity/cs/account/network/privatesubnet1"
PRIV_SUBNET_1_VAL=$(echo "${SUBNET_LIST_VAL}" | jq -r '.private[0]')
refresh_ssm_param "${PRIV_SUBNET_1_SSM}" "${PRIV_SUBNET_1_VAL}" "networking" "na" "vpc" "unity-all-cs-networking-privateSubnet1Ssm"

#
# Create SSM:
# /unity/cs/account/network/privatesubnet2
#
PRIV_SUBNET_2_SSM="/unity/cs/account/network/privatesubnet2"
PRIV_SUBNET_2_VAL=$(echo "${SUBNET_LIST_VAL}" | jq -r '.private[1]')
refresh_ssm_param "${PRIV_SUBNET_2_SSM}" "${PRIV_SUBNET_2_VAL}" "networking" "na" "vpc" "unity-all-cs-networking-privateSubnet2Ssm"
