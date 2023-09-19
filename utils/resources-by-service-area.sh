#!/bin/bash

export AWS_PAGER=""

# Fetches the resources based on the provided query.
getResources() {
  local QUERY=$1
  aws resourcegroupstaggingapi get-resources | jq -r "$QUERY"
}

# Gets the count of resources based on the provided query.
getResourcesCount() {
  local QUERY=$1
  getResources "$QUERY" | wc -l
}

# Prints a summary of tagging including the count of tagged and untagged resources for each tag key.
printTaggingSummary() {
  echo "-----------------------------------------------"
  printf "%-20s | %-6s | %-10s\n" "Tag Category" "Tagged" "Not Tagged"
  echo "-----------------------------------------------"

  for TAG_KEY in "${TAG_KEYS[@]}"; do
    TAGGED=$(getResourcesCount ".ResourceTagMappingList[] | select(contains({Tags: [{Key: \"$TAG_KEY\" } ]})) | .ResourceARN")
    NOT_TAGGED=$(getResourcesCount ".ResourceTagMappingList[] | select(contains({Tags: [{Key: \"$TAG_KEY\" } ]}) | not) | .ResourceARN")
    printf "%-20s | %-6s | %-10s\n" "$TAG_KEY" "$TAGGED" "$NOT_TAGGED"
  done
}

# Prints details of tag key-values including the expected and extra values found.
printTagKeyValueDetails() {
  echo "------------------------------------"
  printf "%-15s | %-23s\n" "$TAG_KEY" "Number of Resources"
  echo "------------------------------------"

  local AWS_TAG_VALUES=$(getResources ".ResourceTagMappingList[].Tags[]? | select(.Key == \"$TAG_KEY\") | .Value" | sort | uniq)

  echo "### Expected Values ###"
  for EXPECTED_VALUE in "${EXPECTED_VALUES_ARRAY[@]}"; do
    local RESOURCE_COUNT=$(getResourcesCount ".ResourceTagMappingList[] | select(.Tags[]? | (.Key == \"$TAG_KEY\" and .Value == \"$EXPECTED_VALUE\")) | .ResourceARN")
    FOUND_VALUES["$EXPECTED_VALUE"]=$RESOURCE_COUNT
    printf "%-15s | %-23s\n" "$EXPECTED_VALUE" "${RESOURCE_COUNT} found"
  done

  local EXTRA_VALUES_FOUND=()
  for AWS_TAG_VALUE in $AWS_TAG_VALUES; do
    if [[ ! " ${EXPECTED_VALUES_ARRAY[@]} " =~ " $AWS_TAG_VALUE " ]]; then
      local RESOURCE_COUNT=$(getResourcesCount ".ResourceTagMappingList[] | select(.Tags[]? | (.Key == \"$TAG_KEY\" and .Value == \"$AWS_TAG_VALUE\")) | .ResourceARN")
      EXTRA_VALUES_FOUND+=("$AWS_TAG_VALUE: $RESOURCE_COUNT")
    fi
  done

  if [ ${#EXTRA_VALUES_FOUND[@]} -gt 0 ]; then
    echo "### Extra Values Found ###"
    for EXTRA_VALUE_FOUND in "${EXTRA_VALUES_FOUND[@]}"; do
      IFS=':' read -r EXTRA_VALUE RESOURCE_COUNT <<< "$EXTRA_VALUE_FOUND"
      printf "%-15s | %-23s\n" "$EXTRA_VALUE" "${RESOURCE_COUNT} found"
    done
    echo
  fi
}

# Prints the details of untagged resources based on specific patterns and labels.
printUntaggedResourceDetails() {
  echo "-------------------------------------------------"
  printf "%-8s | %-43s\n" "Category" "Number of Suspected Untagged Resources"
  echo "-------------------------------------------------"

  for TAG_KEY_PATTERN_LABEL in "${TAG_KEY_PATTERN_LABELS[@]}"; do
    IFS=':' read -r PATTERN LABEL <<< "$TAG_KEY_PATTERN_LABEL"
    local TOTAL_COUNT=0
    for TAG_KEY in "${TAG_KEYS[@]}"; do
      local RESOURCE_COUNT=$(getResourcesCount ".ResourceTagMappingList[] | select((contains({Tags: [{Key: \"$TAG_KEY\" } ]}) | not) and (.ResourceARN | test(\"$PATTERN\"))) | .ResourceARN")
      TOTAL_COUNT=$((TOTAL_COUNT + RESOURCE_COUNT))
    done
    printf "%-8s | %-43s\n" "$LABEL" "$TOTAL_COUNT suspected untagged"
  done
}

# Main section
echo "###################################################################"
echo "##################           MCP-DEV             ##################"
echo "###################################################################"
echo
echo "### TAGGING SUMMARY ###"
TAG_KEYS=("Venue" "ServiceArea" "CapVersion" "Component" "Name" "Proj" "CreatedBy" "Env" "Stack")
printTaggingSummary

echo
echo "### TAG KEY-VALUE DETAILS ###"
declare -A EXPECTED_TAG_VALUES=(
  ["Venue"]="dev test prod sips-test"
  ["ServiceArea"]="cs sps ds as ads uiux"
  ["Env"]=""
  ["CapVersion"]=""
  ["Component"]="SDAP HySDS dockerstore"
  ["Proj"]=""
  ["CreatedBy"]=""
  ["Stack"]=""
)
for TAG_KEY in "${!EXPECTED_TAG_VALUES[@]}"; do
  IFS=' ' read -r -a EXPECTED_VALUES_ARRAY <<< "${EXPECTED_TAG_VALUES[$TAG_KEY]}"
  declare -A FOUND_VALUES
  printTagKeyValueDetails
done

TAG_KEY_PATTERN_LABELS=(
  "ucs|galen|ryan|tom|hollins|ramesh|rmaddego|molen|apigw|apigateway:U-CS"
  "uds|cumulus:U-DS"
  "uads|jmcduffi|dockstore|esarkiss|nlahaye|jupyter:U-ADS"
  "usps|u-sps|sps-api|luca|ryan|hysds:U-SPS"
  "bcdp:U-AS"
  "gmanipon|on-demand:U-OD"
  "anil|tapella|natha:U-UI"
)

echo
echo "### UNTAGGED RESOURCE DETAILS ###"
printUntaggedResourceDetails
