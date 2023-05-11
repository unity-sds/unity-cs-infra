#!/bin/bash

cd $1

# Init
terraform init

# Setup workspace
terraform workspace select ${TARGET_ENV}_${TARGET_STAGE}_${TARGET_PROJECT}_${TARGET_OWNER} || terraform workspace new ${TARGET_ENV}_${TARGET_STAGE}_${TARGET_PROJECT}_${TARGET_OWNER}

if [[ $2 == "destroy" ]]
then
    # Destroy
    terraform destroy -auto-approve -var-file=MCP-DEV.tfvars -var-file=gh_actions.tfvars -var-file=mcp.tfvars
else
    # Plan
    terraform plan -var-file=MCP-DEV.tfvars -var-file=gh_actions.tfvars -var-file=mcp.tfvars -out=./tf.plan

    # Apply
    terraform apply -auto-approve ./tf.plan
fi
