data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "vpc_id" {
  name = "/unity/cs/account/network/vpc_id"
}

data "aws_ssm_parameter" "subnet_list" {
  name = "/unity/cs/account/network/subnet_list"
}

#data "aws_ssm_parameter" "cluster_sg" {
#  name = "/unity/account/eks/cluster_sg"
#}
#
#data "aws_ssm_parameter" "node_sg" {
#  name = "/unity/account/eks/node_sg"
#}

#data "aws_ssm_parameter" "eks_iam_node_role" {
#  name = "/unity/account/eks/eks_iam_node_role"
#}
#
#data "aws_ssm_parameter" "eks_iam_role" {
#  name = "/unity/account/eks/eks_iam_role"
#}

data "aws_ssm_parameter" "eks_ami_1_27" {
  name = "/unity/account/eks/amis/aml2-eks-1-27"
}

data "aws_ssm_parameter" "eks_ami_1_26" {
  name = "/unity/account/eks/amis/aml2-eks-1-26"
}

data "aws_ssm_parameter" "eks_ami_1_25" {
  name = "/unity/account/eks/amis/aml2-eks-1-25"
}
#
#data "aws_ssm_parameter" "eks_ami_1_24" {
#  name = "/unity/account/eks/amis/aml2-eks-1-24"
#}

data "aws_iam_policy" "mcp_operator_policy" {
  name = "mcp-tenantOperator-AMI-APIG"
}

data "aws_iam_policy" "datalakekinesis" {
  name = "DatalakeKinesisPolicy"
}

data "aws_iam_policy" "mcptools" {
  name = "McpToolsAccessPolicy"
}

data "aws_iam_policy" "ebs_csi_policy" {
  name = "U-CS_Service_Policy"
}

data "aws_iam_policy" "aws-managed-load-balancer-policy" {
  arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

data "aws_ebs_default_kms_key" "current" {}