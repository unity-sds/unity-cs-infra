#!/bin/bash

cd $1

# Init
terraform init

# Plan
terraform plan -var-file=MCP-DEV.tfvars -var-file=gh_actions.tfvars -var-file=mcp.tfvars -out=./tf.plan

# Apply
terraform apply -auto-approve -var-file=MCP-DEV.tfvars -var-file=gh_actions.tfvars -var-file=mcp.tfvars ./tf.plan
