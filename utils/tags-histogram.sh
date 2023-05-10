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
      :
    else
      echo "RESOURCES WITH '${1}' TAG:"
      echo "${TAG_VALUES}"
      echo
    fi
}

declare -a tags=(
  "Venue"        "venue"
  "ServiceArea"  "serviceArea"
  "CapVersion"   "capVersion"
  "Component"    "component"
  "Name"         "name"
  "Proj"         "proj"
  "CreatedBy"    "createdBy"
  "Env"          "env"
  "Stack"        "stack"
                )
for tag in "${tags[@]}"; do
   getResourceCountsWithTag "$tag"
done