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

echo "Starting deployment..."

# Apply Terraform configuration
echo "Applying Terraform configuration..."
terraform init
terraform apply -auto-approve

echo "Waiting 120 seconds for EC2 instance to initialize..."
sleep 120

# Get the target group ARN
TARGET_GROUP_ARN=$(aws --profile "$AWS_PROFILE" elbv2 describe-target-groups \
    --names ucs-httpd-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# Get the instance ID of the old EC2 by its Name tag
OLD_INSTANCE_ID=$(aws --profile "$AWS_PROFILE" ec2 describe-instances \
    --filters "Name=tag:Name,Values=shared-services-httpd" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

if [ -n "$OLD_INSTANCE_ID" ]; then
    echo "Deregistering old EC2 instance ($OLD_INSTANCE_ID) from target group..."
    aws --profile "$AWS_PROFILE" elbv2 deregister-targets \
        --target-group-arn "$TARGET_GROUP_ARN" \
        --targets "Id=$OLD_INSTANCE_ID"
    
    echo "Old instance deregistered successfully"
else
    echo "No running instance found with name 'shared-services-httpd'"
fi

# Clean up backend config and Terraform files
rm -f backend.tf
rm -f .terraform.lock.hcl
rm -rf .terraform
echo "Cleaned up Terraform files"

echo "Deployment complete!" 