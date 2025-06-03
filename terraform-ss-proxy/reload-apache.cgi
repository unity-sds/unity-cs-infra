#!/bin/bash

# Set variables
S3_BUCKET="REPLACE_WITH_S3_BUCKET_NAME"
LOCAL_FILE="/etc/apache2/sites-enabled/unity-cs.conf"
TEMP_FILE="/tmp/unity-cs.conf"
SLACK_WEBHOOK=$(aws ssm get-parameter --name "/unity/shared-services/slack/apache-config-webhook-url" --with-decryption --query "Parameter.Value" --output text)

# Function to send message to Slack and exit
send_to_slack() {
    local message="$1"
    local exit_code="$2"
    local env_prefix="[Unity-venue-${ENVIRONMENT}] "
    curl  --silent --output /dev/null -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"${env_prefix}${message}\"}" \
        "${SLACK_WEBHOOK}"
}

# Download files from S3
aws s3 sync s3://${S3_BUCKET}/ /etc/apache2/venues.d/ --exclude "*" --include "*.conf" --quiet

# Test the config
echo "Content-type: application/json"
echo ""
CONFIG_TEST=$(sudo apache2ctl configtest 2>&1)
if [[ "$CONFIG_TEST" != *"Syntax OK"* ]]; then
    send_to_slack "❌ Apache config sync failed: Failed Config Test" 1
    echo '{"status":"error","message":"Failed to validate config"}'
else

    # Log the request for auditing
    echo "[$(date)] Apache config reload requested" >> /var/log/apache2/reload.log

    # Execute the graceful reload
    RESULT=$(sudo /usr/sbin/apachectl graceful 2>&1)
    SUCCESS=$?

    if [ $SUCCESS -eq 0 ]; then
        echo '{"status":"success","message":"Apache configuration reloaded successfully"}'
    else
        echo '{"status":"error","message":"Failed to reload Apache configuration: '"$RESULT"'"}'
    fi
fi