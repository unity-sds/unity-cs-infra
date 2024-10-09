#!/bin/bash

# ================================================
# This bash script automates the process of
# creating or updating an IAM role (Unity-CS_Service_Role)
# for MDPS, attaching multiple policies to it,
# and creating an instance profile for that role.
# ================================================

ROLE_NAME="Unity-CS_Service_Role"
POLICY_LIST=(AmazonEC2ContainerRegistryPowerUser AmazonS3ReadOnlyAccess AmazonSSMManagedInstanceCore CloudWatchAgentServerPolicy DatalakeKinesisPolicy McpToolsAccessPolicy U-CS_Service_Policy U-CS_Service_Policy_Ondemand)
CUSTOM_POLICY_LIST=(U-CS_Service_Policy U-CS_Service_Policy_Ondemand)

# Required role for spot ec2/fleet creation
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com 2>/dev/null || true

## Get the account number
ACCOUNT_NUMBER=$(aws sts get-caller-identity --query Account --output text)
echo "Account Number: $ACCOUNT_NUMBER"

# Function to create or update a policy
create_or_update_policy() {
    local policy_name=$1
    local policy_file=$2
    
    if aws iam get-policy --policy-arn arn:aws:iam::${ACCOUNT_NUMBER}:policy/${policy_name} 2>/dev/null; then
        echo "Updating policy ${policy_name}..."
        policy_version=$(aws iam create-policy-version --policy-arn arn:aws:iam::${ACCOUNT_NUMBER}:policy/${policy_name} --policy-document file://${policy_file} --set-as-default --query 'PolicyVersion.VersionId' --output text)
        aws iam delete-policy-versions --policy-arn arn:aws:iam::${ACCOUNT_NUMBER}:policy/${policy_name} --versions-to-delete $(aws iam list-policy-versions --policy-arn arn:aws:iam::${ACCOUNT_NUMBER}:policy/${policy_name} --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text)
    else
        echo "Creating policy ${policy_name}..."
        aws iam create-policy \
            --policy-name ${policy_name} \
            --policy-document file://${policy_file} \
            --description "Policy for automated U-CS Operations" \
            --tags Key=ServiceArea,Value=U-CS
    fi
}

# Check if role exists, create if it doesn't
if ! aws iam get-role --role-name ${ROLE_NAME} 2>/dev/null; then
    echo "Creating role ${ROLE_NAME}..."
    aws iam create-role \
        --role-name ${ROLE_NAME} \
        --permissions-boundary arn:aws:iam::${ACCOUNT_NUMBER}:policy/mcp-tenantOperator-AMI-APIG \
        --assume-role-policy-document file://U-CS_Service_Role_Trust_Policy.json
else
    echo "Role ${ROLE_NAME} already exists."
fi

# Add or update the inline policy
echo "Adding/Updating inline policy U-CS_Minimum_ECS-Policy..."
aws iam put-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-name U-CS_Minimum_ECS-Policy \
    --policy-document file://Minimum_ECS_Policy.json

# Create or update custom managed policies
for POLICY_NAME in "${CUSTOM_POLICY_LIST[@]}"; do
    create_or_update_policy ${POLICY_NAME} "${POLICY_NAME}.json"
done

# Attach policies to the role
for POLICY_NAME in "${POLICY_LIST[@]}"; do
    if [[ " ${CUSTOM_POLICY_LIST[@]} " =~ " ${POLICY_NAME} " ]]; then
        POLICY_ARN="arn:aws:iam::${ACCOUNT_NUMBER}:policy/${POLICY_NAME}"
    else
        POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text)
    fi
    
    echo "Attaching policy ${POLICY_NAME} to role ${ROLE_NAME}..."
    aws iam attach-role-policy \
        --role-name ${ROLE_NAME} \
        --policy-arn ${POLICY_ARN}
done

# Create or update instance profile
if ! aws iam get-instance-profile --instance-profile-name ${ROLE_NAME}-instance-profile 2>/dev/null; then
    echo "Creating instance profile ${ROLE_NAME}-instance-profile..."
    aws iam create-instance-profile --instance-profile-name ${ROLE_NAME}-instance-profile
    aws iam add-role-to-instance-profile \
        --instance-profile-name ${ROLE_NAME}-instance-profile \
        --role-name ${ROLE_NAME}
else
    echo "Instance profile ${ROLE_NAME}-instance-profile already exists."
    # Ensure the role is attached to the instance profile
    aws iam add-role-to-instance-profile \
        --instance-profile-name ${ROLE_NAME}-instance-profile \
        --role-name ${ROLE_NAME} 2>/dev/null || true
fi

echo "Role and policies setup completed."