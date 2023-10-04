#!/bin/sh

GITHUB_TOKEN=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

git clone https://${GITHUB_TOKEN}@github.com/unity-sds/cfn-ps-jpl-unity-sds.git

exit 

rm -f nightly_output.txt

bash deploy.sh
#bash step2.sh &
#sleep 10
bash destroy.sh

cat nightly_output.txt

OUTPUT=$(cat nightly_output.txt)

WEBHOOK_URL="https://hooks.slack.com/workflows/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"

curl -X POST -H 'Content-type: application/json' --data '{"text": "'"${OUTPUT}"'"}' $WEBHOOK_URL
