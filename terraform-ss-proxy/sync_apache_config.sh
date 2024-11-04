#!/bin/bash

# Set variables
S3_BUCKET="ucs-ss-config"
S3_FILE_PATH="unity-cs.conf"
LOCAL_FILE="/etc/apache2/sites-enabled/unity-cs.conf"
TEMP_FILE="/tmp/unity-cs.conf"

# Check if aws cli is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Download the file from S3 to a temp location
if aws s3 cp "s3://${S3_BUCKET}/${S3_FILE_PATH}" "${TEMP_FILE}"; then
    echo "Successfully downloaded configuration from S3"
else
    echo "Failed to download configuration from S3"
    exit 1
fi

# Check if the local file exists
if [ ! -f "${LOCAL_FILE}" ]; then
    echo "Local configuration file does not exist. Creating new one."
    sudo mv "${TEMP_FILE}" "${LOCAL_FILE}"
    sudo chown root:root "${LOCAL_FILE}"
    sudo chmod 644 "${LOCAL_FILE}"
    sudo systemctl reload apache2
    exit 0
fi

# Compare the files
if diff "${TEMP_FILE}" "${LOCAL_FILE}" >/dev/null; then
    echo "No changes detected in configuration"
    rm "${TEMP_FILE}"
else
    echo "Changes detected in configuration. Testing new config..."
    
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
        rm "${TEMP_FILE}"
        rm "${BACKUP_FILE}"
    else
        echo "Apache configuration test failed. Reverting to original configuration..."
        sudo mv "${BACKUP_FILE}" "${LOCAL_FILE}"
        rm "${TEMP_FILE}"
        echo "Kept original configuration file"
        exit 1
    fi
fi 