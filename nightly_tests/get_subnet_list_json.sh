#!/bin/bash

# Use AWS CLI to get the VPC ID
vpc_id=$(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text)

# Use AWS CLI to get the IDs of the first two public subnets
public_subnet_ids=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=map-public-ip-on-launch,Values=true --query "Subnets[0:4].SubnetId" --output text)

#echo "PUB SUBNETS: ${public_subnet_ids}"

# Use AWS CLI to get the IDs of the first two private subnets
private_subnet_ids=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$vpc_id Name=map-public-ip-on-launch,Values=false --query "Subnets[0:4].SubnetId" --output text)

#echo "PRIV SUBNETS: ${private_subnet_ids}"

# Assign subnet IDs to variables
PUB_SUBNET_1=$(echo $public_subnet_ids | awk '{print $1}')
PUB_SUBNET_2=$(echo $public_subnet_ids | awk '{print $2}')
PRIV_SUBNET_1=$(echo $private_subnet_ids | awk '{print $1}')
PRIV_SUBNET_2=$(echo $private_subnet_ids | awk '{print $2}')

# Print out the results
#echo "Public Subnet 1: $PUB_SUBNET_1"
#echo "Public Subnet 2: $PUB_SUBNET_2"
#echo "Private Subnet 1: $PRIV_SUBNET_1"
#echo "Private Subnet 2: $PRIV_SUBNET_2"

echo "{ \"public\": [\"${PUB_SUBNET_1}\", \"${PUB_SUBNET_2}\"], \"private\": [\"${PRIV_SUBNET_1}\", \"${PRIV_SUBNET_2}\"] }"
