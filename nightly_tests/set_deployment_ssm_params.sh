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
    lookup=$(aws ssm get-parameter --name "$key" 1>/dev/null)
    if [[ `echo "${lookup}" | grep -q "ParameterNotFound" && echo no` == "no" ]]; then
        echo "SSM param ${key} not found.  Not attempting a delete."
    else
        aws ssm delete-parameter --name "${key}" || echo "ERROR: SSM delete failed for $key"
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

get_ssm_val() {
    local key=$1
    aws ssm get-parameter --name ${key} --with-decryption --query 'Parameter.Value' --output text
}

#
# Create SSM:
# /unity/deployment/<PROJECT_NAME>/<VENUE_NAME>/project-name
#
PROJECT_NAME_SSM="/unity/${PROJECT_NAME}/${VENUE_NAME}/project-name"
PROJECT_NAME_VAL="${PROJECT_NAME}"
refresh_ssm_param "${PROJECT_NAME_SSM}" "${PROJECT_NAME_VAL}" "management" "todo" "console" \
 "${PROJECT_NAME}-${VENUE_NAME}-cs-management-projectNameSsm"

#
# Create SSM:
# /unity/deployment/<PROJECT_NAME>/<VENUE_NAME>/venue-name
#
VENUE_NAME_SSM="/unity/${PROJECT_NAME}/${VENUE_NAME}/venue-name"
VENUE_NAME_VAL="${VENUE_NAME}"
refresh_ssm_param "${VENUE_NAME_SSM}" "${VENUE_NAME_VAL}" "management" "todo" "console" \
"${PROJECT_NAME}-${VENUE_NAME}-cs-management-venueNameSsm"

#
# Create SSM:
# /unity/deployment/<PROJECT_NAME>/<VENUE_NAME>/status
#
DEPLOYMENT_STATUS_SSM="/unity/${PROJECT_NAME}/${VENUE_NAME}/deployment/status"
DEPLOYMENT_STATUS_VAL="deploying"
refresh_ssm_param "${DEPLOYMENT_STATUS_SSM}" "${DEPLOYMENT_STATUS_VAL}" "management" "todo" "console" \
"${PROJECT_NAME}-${VENUE_NAME}-cs-management-deploymentStatusSsm"

# Create SSM:
# /unity/${project}/${venue}/cs/monitoring/s3/bucketName
#
S3_HEALTH_CHECK_NAME_SSM="/unity/${PROJECT_NAME}/${VENUE_NAME}/cs/monitoring/s3/bucketName"
S3_HEALTH_CHECK_NAME_VAL="${PROJECT_NAME}-${VENUE_NAME}-monitoring-bucket"
refresh_ssm_param "${S3_HEALTH_CHECK_NAME_SSM}" "${S3_HEALTH_CHECK_NAME_VAL}" "management" "todo" "console" \
"${PROJECT_NAME}-${VENUE_NAME}-cs-management-S3HealthCheckBucketNameSsm"
