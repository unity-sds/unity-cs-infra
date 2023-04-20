#!/bin/bash

cd $1

# Init
terraform init

# Setup workspace
terraform workspace select ${TARGET_ENV}_${TARGET_STAGE}_${TARGET_PROJECT}_${TARGET_OWNER} || terraform workspace new ${TARGET_ENV}_${TARGET_STAGE}_${TARGET_PROJECT}_${TARGET_OWNER}
# Plan
terraform plan -var-file=MCP-DEV.tfvars -var-file=gh_actions.tfvars -var-file=mcp.tfvars -out=./tf.plan

# Apply
terraform apply -auto-approve -var-file=MCP-DEV.tfvars -var-file=gh_actions.tfvars -var-file=mcp.tfvars ./tf.plan
