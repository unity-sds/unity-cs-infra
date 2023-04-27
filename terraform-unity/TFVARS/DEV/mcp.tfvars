# Non-sensitive values for MCP DEV project
ami_id = "ami-0966013e814042b23"
vpc_id = "vpc-0106218dbddd3a753"
igw_id = "igw-0622379cb99c03649"

project       = "unity"
venue         = "dev"


subnets = { public: [], private: ["subnet-059bc4f467275b59d", "subnet-0ebdd997cc3ebe58d"] }
eks_node_groups = { default: ["defaultgroupNodeGroup"], custom: [] }
default_group_node_group_launch_template_name = "defaultgroupNodeGroup"
