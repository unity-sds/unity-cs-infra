FILTERS="suspected un|ServiceArea =|TOTAL|RESOURCES WITH"

echo "Switching environment to MCP-DEV"
eval $(./mcp_keys.sh dev)
echo "Now on MCP-DEV"
echo "Generating tagging summary..."
OUTPUT=`./resources-by-service-area.sh | grep -E "${FILTERS}"`
echo "$OUTPUT"
echo "$OUTPUT" > tag-report-mcp-test.txt

echo "Switching environment to MCP-TEST"
eval $(./mcp_keys.sh test)
echo "Now on MCP-TEST"
echo "Generating tagging summary..."
OUTPUT=`./resources-by-service-area.sh | grep -E "${FILTERS}"`
echo "$OUTPUT"
echo "$OUTPUT" > tag-report-mcp-test.txt

echo "done."
