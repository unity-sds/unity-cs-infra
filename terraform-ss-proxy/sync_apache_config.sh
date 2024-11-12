#!/bin/bash

# Set variables
S3_BUCKET="ucs-ss-config"
S3_FILE_PATH="unity-cs.conf"
LOCAL_FILE="/etc/apache2/sites-enabled/unity-cs.conf"
TEMP_FILE="/tmp/unity-cs.conf"
SLACK_WEBHOOK=$(aws ssm get-parameter --name "/unity/shared-services/slack/apache-config-webhook-url" --with-decryption --query "Parameter.Value" --output text)

# Function to send message to Slack and exit
send_to_slack_and_exit() {
    local message="$1"
    local exit_code="$2"
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        "${SLACK_WEBHOOK}"
    exit "$exit_code"
}

# Check if aws cli is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    send_to_slack_and_exit "❌ Apache config sync failed: AWS CLI not installed" 1
fi

# Download the file from S3 to a temp location
if ! aws s3 cp "s3://${S3_BUCKET}/${S3_FILE_PATH}" "${TEMP_FILE}"; then
    echo "Failed to download configuration from S3"
    send_to_slack_and_exit "❌ Apache config sync failed: Unable to download from S3" 1
fi

# Check if the local file exists
if [ ! -f "${LOCAL_FILE}" ]; then
    echo "Local configuration file does not exist. Creating new one."
    sudo mv "${TEMP_FILE}" "${LOCAL_FILE}"
    sudo chown root:root "${LOCAL_FILE}"
    sudo chmod 644 "${LOCAL_FILE}"
    sudo systemctl reload apache2
    send_to_slack_and_exit "✅ New Apache configuration created and applied" 0
fi

# Compare the files
if diff "${TEMP_FILE}" "${LOCAL_FILE}" >/dev/null; then
    echo "No changes detected in configuration"
    rm "${TEMP_FILE}"
    exit 0
else
    echo "Changes detected in configuration. Testing new config..."
    
    # Generate diff for potential notification
    DIFF_OUTPUT=$(diff "${TEMP_FILE}" "${LOCAL_FILE}" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
    
    # Create a backup of the current config
    BACKUP_FILE="${LOCAL_FILE}.backup"
    sudo cp "${LOCAL_FILE}" "${BACKUP_FILE}"
    
    # Test the new configuration without moving it yet
    sudo cp "${TEMP_FILE}" "${LOCAL_FILE}"
    
    if sudo apache2ctl configtest; then
        echo "Apache configuration test passed. Applying changes..."
        sudo chown root:root "${LOCAL_FILE}"
        sudo chmod 644 "${LOCAL_FILE}"
        sudo systemctl reload apache2
        echo "Apache configuration updated successfully"
        sudo rm "${TEMP_FILE}"
        sudo rm "${BACKUP_FILE}"
        send_to_slack_and_exit "✅ Apache configuration updated successfully\nChanges made:\n${DIFF_OUTPUT}" 0
    else
        echo "Apache configuration test failed. Reverting to original configuration..."
        sudo mv "${BACKUP_FILE}" "${LOCAL_FILE}"
        rm "${TEMP_FILE}"
        echo "Kept original configuration file"
        send_to_slack_and_exit "❌ Apache configuration test failed. Original configuration kept." 1
    fi
fi
