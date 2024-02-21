#!/bin/bash

# Directory containing the log directories
LOG_DIR="/home/ubuntu/unity-cs-infra/nightly_tests/nightly_logs"

# Print current date and time 
echo "Current date and time: $(date)"

# Find and attempt to delete directories older than 2 weeks 
find "$LOG_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec echo "Deleting directory: {}" \; -exec rm -r {} \;

