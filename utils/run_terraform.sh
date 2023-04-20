#!/bin/bash

cd $1

# Init
terraform init

# Plan
terraform plan -var-file=../../../terraform-unity/MCP-DEV.tfvars -var-file=gh_actions.tfvars -var-file=mcp.tfvars -out=./tf.plan

# Apply
terraform apply -auto-approve -var-file=../../../terraform-unity/MCP-DEV.tfvars -var-file=gh_actions.tfvars -var-file=mcp.tfvars ./tf.plan
