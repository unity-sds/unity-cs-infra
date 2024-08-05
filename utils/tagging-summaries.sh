#!/bin/bash

FILTERS="suspected untagged|ServiceArea|TOTAL|RESOURCES WITH|OTHER"
# WEBHOOK_URL= XXXXXXXXXXXXXXXXXXXXXXXXX
echo "────────────────────────────────────────"
echo "              MCP-DEV                   "
echo "────────────────────────────────────────"
# eval $(./mcp_keys.sh dev)

OUTPUT=$(./resources-by-service-area.sh)

TAG_SUMMARY=$(echo "$OUTPUT" | grep -E "─ TAGGING SUMMARY ─" -A 2)
SERVICE_AREA_DETAILS=$(echo "$OUTPUT" | grep -E "─ SERVICE AREA DETAILS ─" -A 5)
UNTAGGED_DETAILS=$(echo "$OUTPUT" | grep -E "─ UNTAGGED RESOURCE DETAILS ─" -A 7)
TAG_ANALYSIS=$(echo "$OUTPUT" | grep -E "─ TAG ANALYSIS ─" -A 3)
OTHER=$(echo "$OUTPUT" | grep -E "─ OTHER ─" -A 2)


curl -X POST -H 'Content-type: application/json' --data '{"text": "'"${OUTPUT}"'"}' $WEBHOOK_URL
