#!/bin/bash

# =================================================
# Displays AWS resource ARNs for a service area,
# by looking for resources containing the specified
# 'ServiceArea' tag.
# =================================================
getResourceArnsForServiceArea () {
  export AWS_PAGER=""
  RESOURCES=`aws resourcegroupstaggingapi get-resources \
    --tag-filters "Key=ServiceArea,Values=${1}" \
    --query 'ResourceTagMappingList[*].ResourceARN' \
    --output text`
  RESOURCE_COUNT=`echo $RESOURCES | grep -c 'arn:'`
  echo "----------------------------------"
  if [[ $RESOURCE_COUNT -gt 0 ]]; then
    echo "$1 resources ($RESOURCE_COUNT found):"
    echo $RESOURCES
  else
    echo "$1 resources (0 found)"
  fi
}

getNoServiceAreaResources () {
#  aws resourcegroupstaggingapi get-resources \
#    --tag-filters "Key=ServiceArea,Values=null" \
#    --query 'ResourceTagMappingList[*].ResourceARN' \
#    --output text
  echo "----------------------------------"
  export RESOURCES=`aws resourcegroupstaggingapi get-resources \
    | jq '.ResourceTagMappingList[] | select(contains({Tags: [{Key: "environment"} ]}) | not) | .ResourceARN' \
    | grep "$1"`
  RESOURCE_COUNT=`echo "$RESOURCES" | grep -c 'arn:'`
  echo "$2 has ${RESOURCE_COUNT} suspected un-tagged (missing ServiceArea tag) $2 resources"

  #echo "Examples:"
  #echo "$RESOURCES" | head -3
  #echo "..."
  #echo "$RESOURCES" | tail -3
}

 #| jq '.ResourceTagMappingList[] | select(contains({Tags: [{Key: "ServiceArea"} ]}) | not)'

#getResourceArnsForServiceArea "U-CS"
#getResourceArnsForServiceArea "U-SPS"
#getResourceArnsForServiceArea "U-DS"
#getResourceArnsForServiceArea "U-ADS"
#getResourceArnsForServiceArea "U-AS"

getNoServiceAreaResources "ucs" "U-CS"
getNoServiceAreaResources "uds" "U-DS"
getNoServiceAreaResources "uads" "U-ADS"

echo
getResourceArnsForServiceArea "sps"
getNoServiceAreaResources "usps" "U-SPS"
