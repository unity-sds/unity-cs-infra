#!/bin/bash


getNumResourcesTaggedWithServiceArea () {
  export RESOURCES=`aws resourcegroupstaggingapi get-resources \
    | jq '.ResourceTagMappingList[] | select(contains({Tags: [{Key: "ServiceArea"} ]})) | .ResourceARN' \
    | grep "arn:"`
  RESOURCE_COUNT=`echo "$RESOURCES" | grep -c 'arn:'`
  echo "TOTAL tagged with ServiceArea tag: $RESOURCE_COUNT"
}

getNumResourcesNotTaggedWithServiceArea () {
  export RESOURCES=`aws resourcegroupstaggingapi get-resources \
    | jq '.ResourceTagMappingList[] | select(contains({Tags: [{Key: "ServiceArea"} ]}) | not) | .ResourceARN' \
    | grep "arn:"`
  RESOURCE_COUNT=`echo "$RESOURCES" | grep -c 'arn:'`
  echo "TOTAL NOT tagged with ServiceArea tag: $RESOURCE_COUNT"
}

# =================================================
# Displays AWS resource ARNs for a service area,
# by looking for resources containing the specified
# 'ServiceArea' tag.
# =================================================
getResourcesTaggedWithServiceArea () {
  #export AWS_PAGER=""
  RESOURCES=`aws resourcegroupstaggingapi get-resources \
    --tag-filters "Key=ServiceArea,Values=${1}" \
    --query 'ResourceTagMappingList[*].[ResourceARN]' \
    --output text`
  RESOURCE_COUNT=`echo "$RESOURCES" | grep -c 'arn:'`
  echo
  echo "------------ ServiceArea = ${1} -------------- ($RESOURCE_COUNT found):"
  if [[ $RESOURCE_COUNT -gt 0 ]]; then
    #echo "------------ ServiceArea = ${1} -------------- ($RESOURCE_COUNT found):"
    #echo "$1 resources ($RESOURCE_COUNT found):"
    echo "$RESOURCES" | grep "arn:"
  else
    echo "$1 resources (0 found)"
  fi
}

getNoServiceAreaResources () {
#  aws resourcegroupstaggingapi get-resources \
#    --tag-filters "Key=ServiceArea,Values=null" \
#    --query 'ResourceTagMappingList[*].ResourceARN' \
#    --output text
  export RESOURCES=`aws resourcegroupstaggingapi get-resources \
    | jq '.ResourceTagMappingList[] | select(contains({Tags: [{Key: "ServiceArea"} ]}) | not) | .ResourceARN' \
    | grep -E "$1"`
  RESOURCE_COUNT=`echo "$RESOURCES" | grep -c 'arn:'`
  echo
  echo "------------------------------------------------------------------------"
  echo "$2 has ${RESOURCE_COUNT} suspected un-tagged (missing ServiceArea tag) $2 resources"
  echo "------------------------------------------------------------------------"
  echo "$RESOURCES"
  #echo "Examples:"
  #echo "$RESOURCES" | head -3
  #echo "..."
  #echo "$RESOURCES" | tail -3
}


export AWS_PAGER=""

getNumResourcesTaggedWithServiceArea
getNumResourcesNotTaggedWithServiceArea
echo
getResourcesTaggedWithServiceArea "cs"
getResourcesTaggedWithServiceArea "as"
getResourcesTaggedWithServiceArea "ads"
getResourcesTaggedWithServiceArea "sps"
getResourcesTaggedWithServiceArea "ds"
getNoServiceAreaResources "ucs|galen|ryan|tom|hollins|ramesh|rmaddego|molen|apigw|apigateway" "U-CS"
getNoServiceAreaResources "uds|cumulus" "U-DS"
getNoServiceAreaResources "uads|jmcduffi|dockstore|esarkiss" "U-ADS"
getNoServiceAreaResources "usps|u-sps|sps-api|luca|ryan|hysds" "U-SPS"
getNoServiceAreaResources "bcdp" "U-AS"
getNoServiceAreaResources "gmanipon|on-demand" "U-OD"
getNoServiceAreaResources "nlahaye|anil|tapella|natha" "U-UI"


export OTHER_RESOURCES=`getNoServiceAreaResources "arn" "OTHER" | grep -Ev "ucs|galen|tom|hollins|ramesh|rmaddego|molen|apigw|apigateway|uds|cumulus|uads|jmcduffi|dockstore|esarkiss|usps|u-sps|sps-api|luca|ryan|hysds|bcdp|gmanipon|on-demand|nlahaye|anil|tapella|natha"`
OTHER_RESOURCE_COUNT=`echo "$OTHER_RESOURCES" | grep -c 'arn:'`
echo
echo "$OTHER_RESOURCE_COUNT OTHER suspected un-tagged (missing ServiceArea tag) resources:"
echo "$OTHER_RESOURCES"
#echo
#getResourceArnsForServiceArea "sps"
#getNoServiceAreaResources "usps" "U-SPS"
