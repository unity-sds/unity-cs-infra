data "aws_ssm_parameter" "eks_service_role_arn" {
  name = var.eks_service_role_arn_ssm_parameter
}

data "aws_ssm_parameter" "eks_node_role_arn" {
  name = var.eks_node_role_arn_ssm_parameter
}

data "aws_ssm_parameter" "eks_user_role_arn" {
  name = var.eks_user_role_arn_ssm_parameter
}

data "aws_ssm_parameter" "eks_cluster_ami" {
  name = var.eks_cluster_ami_ssm_parameter
}

data "aws_ssm_parameter" "eks_security_group" {
  name = var.eks_security_group_ssm_parameter
}

data "aws_ssm_parameter" "eks_shared_node_security_group" {
  name = var.eks_shared_node_security_group_ssm_parameter
}

data "aws_ssm_parameter" "eks_subnet_public_a" {
  name = var.eks_subnet_public_a_ssm_parameter
}

data "aws_ssm_parameter" "eks_subnet_public_b" {
  name = var.eks_subnet_public_b_ssm_parameter
}

data "aws_ssm_parameter" "eks_subnet_private_a" {
  name = var.eks_subnet_private_a_ssm_parameter
}

data "aws_ssm_parameter" "eks_subnet_private_b" {
  name = var.eks_subnet_private_b_ssm_parameter
}

data "aws_ssm_parameter" "eks_subnets_private" {
  name = var.eks_subnets_private_ssm_parameter
}

data "aws_ssm_parameter" "venue" {
  name = "/unity/account/venue"
}

data "aws_ssm_parameter" "project" {
  name = "/unity/account/project"
}