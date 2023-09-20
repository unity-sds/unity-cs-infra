#!/bin/sh

bash deploy.sh
bash step2.sh
bash destroy.sh

cat nightly_output.txt

OUTPUT=$(cat nightly_output.txt)

WEBHOOK_URL="https://hooks.slack.com/workflows/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"

curl -X POST -H 'Content-type: application/json' --data '{"text": "'"${OUTPUT}"'"}' $WEBHOOK_URL
