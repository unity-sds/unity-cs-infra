#!/bin/bash


# Input: CloudFormation stack name
STACK_NAME="$1"

# Check if stack name is provided
if [ -z "$STACK_NAME" ]; then
    echo "Usage: $0 <CloudFormation Stack Name>"
    exit 1
fi

# Get all resource IDs from the CloudFormation stack
resources=$(aws cloudformation list-stack-resources --stack-name "$STACK_NAME" --query "StackResourceSummaries[].[ResourceType,PhysicalResourceId]" --output text)

echo "Fetching tags for resources in stack '$STACK_NAME'..."

# Loop through resources and fetch tags
while read -r resourceType resourceId; do
    case $resourceType in
        AWS::ElasticLoadBalancingV2::Listener|AWS::Lambda::Function|AWS::CloudFormation::CustomResource|AWS::SSM::Parameter)
            # Skip fetching tags for these resources
            continue
            ;;
    esac

    echo "Resource: $resourceType, ID: $resourceId"
    case $resourceType in
        AWS::EC2::Instance|AWS::EC2::SecurityGroup|AWS::EC2::LaunchTemplate)
            tags=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$resourceId" --query "Tags[].[Key,Value]" --output text)
            ;;
        AWS::IAM::Role)
            tags=$(aws iam list-role-tags --role-name "$resourceId" --query "Tags[].[Key,Value]" --output text)
            ;;
        AWS::IAM::InstanceProfile)
            # Extract the role name from the instance profile
            roleName=$(aws iam get-instance-profile --instance-profile-name "$resourceId" --query 'InstanceProfile.Roles[0].RoleName' --output text)
            if [ "$roleName" != "None" ]; then
                tags=$(aws iam list-role-tags --role-name "$roleName" --query "Tags[].[Key,Value]" --output text)
            else
                tags=""
            fi
            ;;
        AWS::AutoScaling::AutoScalingGroup)
            # AutoScaling Group names 
            tags=$(aws autoscaling describe-tags --filters "Name=auto-scaling-group,Values=$resourceId" --query "Tags[].[Key,Value]" --output text)
            ;;
        AWS::ElasticLoadBalancingV2::LoadBalancer|AWS::ElasticLoadBalancingV2::TargetGroup)
            # For ELBv2 (ALB/NLB)
            tags=$(aws elbv2 describe-tags --resource-arns "$resourceId" --query "TagDescriptions[0].Tags[].[Key,Value]" --output text)
            ;;
        *)
            echo "Skipping resource type $resourceType for tagging details."
            tags=""
            ;;
    esac
    if [ -n "$tags" ]; then
        while read -r key value; do
            echo "  Tag: $key, Value: $value"
        done <<< "$tags"
    else
        echo "  No tags found or unable to retrieve tags for this resource type."
    fi
    echo # Newline 
done <<< "$resources"


# List of SSM Parameter accessed by cloudformation stack
ssm_parameters=(
  "/unity/core/project"
  "/unity/core/venue"
  "/unity/cs/account/network/vpc_id"
  "/mcp/amis/ubuntu2004-cset"
)

# Loop through the list and fetch each parameter
for param_name in "${ssm_parameters[@]}"; do
  param_value=$(aws ssm get-parameter --name "${param_name}" --query "Parameter.Value" --output text)
  
  # Check if the parameter was successfully retrieved
  if [ $? -eq 0 ]; then
    echo "Parameter Name: ${param_name}"
    echo "Parameter Value: ${param_value}"
    echo "--------------------------------"
  else
    echo "Failed to retrieve value for ${param_name}"
  fi
done
