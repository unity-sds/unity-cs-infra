#!/bin/bash

cd $1

# Init
terraform init

# Setup workspace
terraform workspace select ${TARGET_ENV}_${TARGET_STAGE}_${TARGET_PROJECT}_${TARGET_OWNER} || terraform workspace new ${TARGET_ENV}_${TARGET_STAGE}_${TARGET_PROJECT}_${TARGET_OWNER}

if [[ $2 == "destroy" ]]
then
    # Destroy
    terraform destroy -auto-approve -var-file=gh_actions.tfvars 
else
    # Plan
    terraform plan -var-file=gh_actions.tfvars -out=./tf.plan

    # Apply
    terraform apply -auto-approve ./tf.plan
fi
