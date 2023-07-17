variable "cluster_name" {
  description = "Name for EKS cluster - must be unique in account"
  type = string
}

variable "deployable_name" {
  description = "Name of Unity Deployable"
  type = string
  default = "Base-EKS"
}

variable "deployable_version" {
  description = "Version of Curated EKS stack"
  type = string
  default = "x.x"
}

variable "node_groups" {
  description = <<EOT
  Map of nodegroups of format:
    { node_group_name1 =
      { instance_type = awsInstanceType,
        node_count = int
      },
      node_group_name2 =
      { instance_type = awsInstanceType,
        node_count = int
      }
    }
  EOT
  type = map
  default = {default_group = {instance_type = "m5.xlarge", node_count = 1}}
}

variable "region" {
  description = "AWS Region"
  type = string
  default = "us-west-2"
}

variable "eks_service_role_arn_ssm_parameter" {
  description = "SSM Parameter full path to fetch EKS service role ARN"
  type = string
  default = "/unity/account/roles/eksServiceRoleArn"
}

variable "eks_node_role_arn_ssm_parameter" {
  description = "ssm parameter full path to fetch eks node role arn"
  type = string
  default = "/unity/account/roles/eksInstanceRoleArn"
}

variable "eks_user_role_arn_ssm_parameter" {
  description = "ssm parameter full path to fetch eks node role arn"
  type = string
  default = "/unity/account/roles/mcpRoleArns"
}

variable "eks_cluster_ami_ssm_parameter" {
  description = "ssm parameter full path to fetch eks node role arn"
  type = string
  default = "/unity/account/ami/eksClusterAmi"
}

variable "eks_security_group_ssm_parameter" {
  description = "ssm parameter full path to eks security group"
  type = string
  default = "/unity/account/securityGroups/eksSecurityGroup"
}

variable "eks_shared_node_security_group_ssm_parameter" {
  description = "ssm parameter full path to eks shared node security group"
  type = string
  default = "/unity/account/securityGroups/eksSharedNodeSecurityGroup"
}

variable "eks_subnet_public_a_ssm_parameter" {
  description = "first public subnet in eks vpc configuration"
  type = string
  default = "/unity/account/network/subnets/eks/publicA"
}

variable "eks_subnet_public_b_ssm_parameter" {
  description = "second public subnet in eks vpc configuration"
  type = string
  default = "/unity/account/network/subnets/eks/publicB"
}

variable "eks_subnet_private_a_ssm_parameter" {
  description = "first private subnet in eks vpc configuration"
  type = string
  default = "/unity/account/network/subnets/eks/privateA"
}

variable "eks_subnet_private_b_ssm_parameter" {
  description = "second private subnet in eks vpc configuration"
  type = string
  default = "/unity/account/network/subnets/eks/privateB"
}

variable "eks_subnets_private_ssm_parameter" {
  description = "private subnets in account"
  type = string
  default = "/unity/account/network/subnets/eks/private"
}