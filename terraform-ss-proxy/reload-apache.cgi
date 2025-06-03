#!/bin/bash

# Set variables
S3_BUCKET="REPLACE_WITH_S3_BUCKET_NAME"
ENVIRONMENT="REPLACE_WITH_ENVIRONMENT_NAME"
LOCAL_FILE="/etc/apache2/sites-enabled/unity-cs.conf"
TEMP_FILE="/tmp/unity-cs.conf"
SLACK_WEBHOOK=$(aws ssm get-parameter --name "/unity/shared-services/slack/apache-config-webhook-url" --with-decryption --query "Parameter.Value" --output text)

# Function to send message to Slack and exit
send_to_slack() {
    local message="$1"
    local env_prefix="[Unity-venue-${ENVIRONMENT}] "
    curl  --silent --output /dev/null -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"${env_prefix}${message}\"}" \
        "${SLACK_WEBHOOK}"
}

# Download files from S3
aws s3 sync s3://${S3_BUCKET}/ /etc/apache2/venues.d/ --exclude "*" --include "*.conf" --quiet

# Do short pause to to make sure
sleep 2

# Test the config
echo "Content-type: application/json"
echo ""
CONFIG_TEST=$(sudo /usr/sbin/apachectl configtest 2>&1)
if [[ "$CONFIG_TEST" != *"Syntax OK"* ]]; then
    echo $CONFIG_TEST
    send_to_slack "❌ Apache config sync failed: Failed Config Test"
    logger -t "apache-reload" "Reload Failed: ${CONFIG_TEST}"
    echo '{"status":"error","message":"Failed to validate config"}'
else

    # Log the request for auditing
    logger -t "apache-reload" "Apache config reload requested"

    # Execute the graceful reload
    RESULT=$(sudo /usr/sbin/apachectl graceful 2>&1)
    SUCCESS=$?

    if [ $SUCCESS -eq 0 ]; then
        echo '{"status":"success","message":"Apache configuration reloaded successfully"}'
    else
        echo '{"status":"error","message":"Failed to reload Apache configuration: '"$RESULT"'"}'
    fi
fi