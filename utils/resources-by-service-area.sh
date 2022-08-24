#!/bin/sh

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

getResourceArnsForServiceArea "U-CS"
getResourceArnsForServiceArea "U-SPS"
getResourceArnsForServiceArea "U-DS"
getResourceArnsForServiceArea "U-ADS"
getResourceArnsForServiceArea "U-AS"
