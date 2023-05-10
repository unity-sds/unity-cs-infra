#!/bin/bash

# =================================================
# Displays counts per tag value
# =================================================
getResourceCountsWithTag () {
  TAG_VALUES=$(aws resourcegroupstaggingapi get-resources \
    --tag-filters "Key=${1}" \
    --query 'ResourceTagMappingList[*].Tags[?Key==`'${1}'`].Value' \
    --output text | sort -r | uniq -c)
    if [[ -z "${TAG_VALUES}" ]]; then
#      echo "NO RESOURCES WITH '${1}' TAG:"
#      echo
      :
    else
      echo "RESOURCES WITH '${1}' TAG:"
      echo "${TAG_VALUES}"
      echo
    fi
}

getResourceCountsWithTag "Venue"
getResourceCountsWithTag "venue"

getResourceCountsWithTag "ServiceArea"
getResourceCountsWithTag "serviceArea"

getResourceCountsWithTag "CapVersion"
getResourceCountsWithTag "capVersion"

getResourceCountsWithTag "Component"
getResourceCountsWithTag "component"

getResourceCountsWithTag "Name"
getResourceCountsWithTag "name"

getResourceCountsWithTag "Proj"
getResourceCountsWithTag "proj"

getResourceCountsWithTag "CreatedBy"
getResourceCountsWithTag "createdBy"

getResourceCountsWithTag "Env"
getResourceCountsWithTag "env"

getResourceCountsWithTag "Stack"
getResourceCountsWithTag "stack"
