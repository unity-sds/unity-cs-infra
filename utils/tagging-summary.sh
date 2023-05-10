echo "Switching environment to MCP-DEV"
eval $(./mcp_keys.sh dev)
echo "Now on MCP-DEV"
echo "Generating tagging summary..."
./resources-by-service-area.sh | grep -E "suspected un|ServiceArea =|TOTAL" > tag-report-mcp-dev.txt

echo "Switching environment to MCP-TEST"
eval $(./mcp_keys.sh test)
echo "Now on MCP-TEST"
echo "Generating tagging summary..."
./resources-by-service-area.sh | grep -E "suspected un|ServiceArea =|TOTAL" > tag-report-mcp-test.txt

echo "done."
