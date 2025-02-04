#!/bin/bash

set -e  # Exit on any error

# Check if profile argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <aws-profile>"
    echo "Example: $0 mcp-venue-cm"
    exit 1
fi

AWS_PROFILE=$1
echo "Using AWS Profile: $AWS_PROFILE"

# Verify the AWS profile exists
if ! aws configure list-profiles | grep -q "^${AWS_PROFILE}$"; then
    echo "Error: AWS Profile '$AWS_PROFILE' not found"
    exit 1
fi

# Get venue from SSM
VENUE=$(aws --profile "$AWS_PROFILE" ssm get-parameter --name "/unity/account/venue" --query "Parameter.Value" --output text)
echo "Detected venue: $VENUE"

# Create backend configuration
cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket = "ucs-shared-services-apache-config-${VENUE}"
    key    = "terraform/terraform.tfstate"
    region = "us-west-2"
    profile = "${AWS_PROFILE}"
  }
}
EOF

echo "Starting terraform destroy..."

# Initialize and destroy
terraform init
terraform destroy -auto-approve

# Clean up backend config and Terraform files
rm -f backend.tf
rm -f .terraform.lock.hcl
rm -rf .terraform
echo "Cleaned up Terraform files"

echo "Destroy complete!" 