#!/bin/bash

echo "set_common_ssm_params.sh ..."

#
# Sub-routine to check, and populate if missing
#
populate_if_not_exists_ssm_param() {
    local key=$1
    local capability=$2
    local capVersion=$3
    local component=$4
    local name=$5
    echo "populate_if_not_exists_ssm_param: ${key} ..."
    aws ssm get-parameter --name "$key" 2>ssm_lookup.txt
    if [[ `grep "ParameterNotFound" ssm_lookup.txt | wc -l` == "1" ]]; then
        echo "SSM param ${key} not found.  Enter Value: "
        read user_input
        create_ssm_param "${key}" "${user_input}" "${capability}" "${capVersion}" "${component}" "${name}"
    else
        echo "SSM param ${key} exists. Continuing..."
    fi
    rm ssm_lookup.txt
}

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
        aws ssm delete-parameter --name "${key}"
        if [ $? -ne 0 ]; then
            echo "ERROR: SSM delete failed for $key"
        fi
    fi
    rm ssm_lookup.txt
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

get_ssm_val() {
    local key=$1
    aws ssm get-parameter --name ${key} --with-decryption --query 'Parameter.Value' --output text
}

#
# Create SSM:
# /unity/cs/account/management-console/instancetype
#
MC_INSTANCETYPE_SSM="/unity/cs/account/management-console/instancetype"
MC_INSTANCETYPE_VAL="c6i.xlarge"
refresh_ssm_param "${MC_INSTANCETYPE_SSM}" "${MC_INSTANCETYPE_VAL}" \
    "management" "todo" "console" \
    "unity-all-cs-managementConsole-instanceTypeSsm"

#
# Create SSM:
# /unity/cs/account/privilegedpolicyname
#
CS_PRIVILEGED_POLICY_NAME_SSM="/unity/cs/account/privilegedpolicyname"
CS_PRIVILEGED_POLICY_NAME_VAL="mcp-tenantOperator-AMI-APIG"
refresh_ssm_param "${CS_PRIVILEGED_POLICY_NAME_SSM}" "${CS_PRIVILEGED_POLICY_NAME_VAL}" \
    "management" "todo" "console" \
    "unity-all-cs-privilegedpolicynameSsm"

#
# Create SSM:
# /unity/cs/github/username
#
GITHUB_USERNAME_SSM="/unity/cs/github/username"
populate_if_not_exists_ssm_param "${GITHUB_USERNAME_SSM}" \
    "management" "todo" "console" \
    "unity-all-cs-githubUsernameSsm"
GITHUB_USERNAME_VAL=$(get_ssm_val "$GITHUB_USERNAME_SSM")

#
# Create SSM:
# /unity/cs/github/useremail
#
GITHUB_USEREMAIL_SSM="/unity/cs/github/useremail"
populate_if_not_exists_ssm_param "${GITHUB_USEREMAIL_SSM}" \
    "management" "todo" "console" \
    "unity-all-cs-githubUseremailSsm"
GITHUB_USEREMAIL_VAL=$(get_ssm_val "$GITHUB_USEREMAIL_SSM")

#
# Create SSM:
# /unity/cs/githubtoken
#
GITHUB_TOKEN_SSM="/unity/cs/githubtoken"
populate_if_not_exists_ssm_param "${GITHUB_TOKEN_SSM}" \
    "management" "todo" "console" \
    "unity-all-cs-githubtokenSsm"
GITHUB_TOKEN_VAL=$(get_ssm_val "$GITHUB_TOKEN_SSM")

#
# Create SSM:
# /unity/ci/slack-web-hook-url
#
SLACK_WEB_HOOK_URL_SSM="/unity/ci/slack-web-hook-url"
populate_if_not_exists_ssm_param "${SLACK_WEB_HOOK_URL_SSM}" \
    "management" "todo" "console" \
    "unity-all-cs-slackWebHookUrlSsm"
SLACK_WEB_HOOK_URL_VAL=$(get_ssm_val "$SLACK_WEB_HOOK_URL_SSM")

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

#
# Create SSM:
# 
EKS_AMI_25_SSM="/unity/account/eks/amis/aml2-eks-1-25"
EKS_AMI_25_VAL=$(get_ssm_val "/mcp/amis/aml2-eks-1-25")
refresh_ssm_param "${EKS_AMI_25_SSM}" "${EKS_AMI_25_VAL}" "processing" "na" "vpc" "unity-all-cs-processing-aml2Eks125Ssm"

#
# Create SSM:
# 
EKS_AMI_26_SSM="/unity/account/eks/amis/aml2-eks-1-26"
EKS_AMI_26_VAL=$(get_ssm_val "/mcp/amis/aml2-eks-1-26")
refresh_ssm_param "${EKS_AMI_26_SSM}" "${EKS_AMI_26_VAL}" "processing" "na" "vpc" "unity-all-cs-processing-aml2Eks126Ssm"

#
# Create SSM:
# 
EKS_AMI_27_SSM="/unity/account/eks/amis/aml2-eks-1-27"
EKS_AMI_27_VAL=$(get_ssm_val "/mcp/amis/aml2-eks-1-27")
refresh_ssm_param "${EKS_AMI_27_SSM}" "${EKS_AMI_27_VAL}" "processing" "na" "vpc" "unity-all-cs-processing-aml2Eks127Ssm"
