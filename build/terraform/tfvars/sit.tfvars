
# stage: dev, sandbox, sit, uat, ops
stage = "sit"

# SIT VPC
vpc_id = "vpc-"

# SIT VPC Security Group
aws_vpc_default_security_group_id = ["sg-"]

# subnet_ids
private_subnets = ["subnet-","subnet-"]

# The ID of the EFS to mount the services on.
efs_id = "fs-"

# EFS subnet 1
private_subnet_1 = "subnet-"

# EFS subnet 2
private_subnet_2 = "subnet-"
