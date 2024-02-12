#!/bin/bash


# LIST OF AWS RESOURCES CREATED BY CLOUFFORMATION STACK
#
# IAM Roles:
# LambdaExecutionRole
# InstanceRole

# IAM Instance Profile:
# InstanceProfile

# Lambda Function:
# RandomStringLambdaFunction

# SSM Parameters:
# UnityProjectName
# UnityVenueName

# EC2 Launch Template:
# ManagmentConsoleLaunchTemplate

# AutoScaling Group:
# DeployerAutoScalingGroup

# Security Groups:
# ManagementConsoleSecurityGroup
# ALBSecurityGroup

# Elastic Load Balancing (ELB):
# MCTargetGroup
# ApplicationLoadBalancer
# PublicLoadBalancerListener

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
