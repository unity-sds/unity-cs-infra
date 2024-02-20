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


# SSM parameters used as inputs for the CloudFormation stack
ssm_parameters_input=(
  "/unity/testing/nightly/vpc-id"
  "/unity/testing/nightly/publicsubnet1"
  "/unity/testing/nightly/publicsubnet2"
  "/unity/testing/nightly/privatesubnet1"
  "/unity/testing/nightly/privatesubnet2"
  "/unity/testing/nightly/instancetype"
  "/unity/testing/nightly/privilegedpolicyname"
#  "/unity/testing/nightly/githubtoken"
  "/unity/testing/nightly/venue"
  "/unity/testing/nightly/accountname"
)

# Echo the SSM parameters used for the CloudFormation stack deployment
echo "SSM Parameters inputted into the CloudFormation stack deployment:"

# Loop through the list of input SSM parameters and echo their names and values
for param_name in "${ssm_parameters_input[@]}"; do
  param_value=$(aws ssm get-parameter --name "${param_name}" --query "Parameter.Value" --output text)
  
  if [ $? -eq 0 ]; then
    echo "Input Parameter Name: ${param_name}"
    echo "Parameter Value: ${param_value}"
  else
    echo "Failed to retrieve value for ${param_name}"
  fi
  echo "--------------------------------"
done





# SSM Parameters accessed by the CloudFormation stack
ssm_parameters_accessed=(
  "/mcp/amis/ubuntu2004-cset"
)

echo ""
echo "SSM Parameters accessed by CloudFormation stack:"
# Loop through the list of accessed parameters and get each parameter
for param_name in "${ssm_parameters_accessed[@]}"; do
  param_value=$(aws ssm get-parameter --name "${param_name}" --query "Parameter.Value" --output text)
  
  if [ $? -eq 0 ]; then
    echo "Accessed Parameter Name: ${param_name}"
    echo "Parameter Value: ${param_value}"
  else
    echo "Failed to retrieve value for ${param_name}"
  fi
  echo "--------------------------------"
done




# SSM Parameters created by the CloudFormation stack
ssm_parameters_created=(
  "/unity/core/project"
  "/unity/core/venue"
  "/unity/cs/account/network/vpc_id"
)

echo ""
echo "SSM Parameters created by CloudFormation stack:"
# Loop through the list of created parameters and get each parameter
for param_name in "${ssm_parameters_created[@]}"; do
  # Attempt to fetch the value of the created parameter
  param_value=$(aws ssm get-parameter --name "${param_name}" --query "Parameter.Value" --output text)
  
  # Check if the parameter was successfully retrieved
  if [ $? -eq 0 ]; then
    echo "Created Parameter Name: ${param_name}"
    echo "Parameter Value: ${param_value}"
  else
    echo "Failed to retrieve or parameter may not exist yet for ${param_name}"
  fi
  echo "--------------------------------"
done

