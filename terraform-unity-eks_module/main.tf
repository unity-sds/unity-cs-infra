data "aws_ssm_parameter" "vpc_id" {
  name = "/unity/account/network/vpc_id"
}

data "aws_ssm_parameter" "subnet_list" {
  name = "/unity/account/network/subnet_list"
}

data "aws_ssm_parameter" "cluster_sg" {
  name = "/unity/account/eks/cluster_sg"
}

data "aws_ssm_parameter" "node_sg" {
  name = "/unity/account/eks/node_sg"
}

data "aws_ssm_parameter" "eks_iam_node_role" {
  name = "/unity/account/eks/eks_iam_node_role"
}

data "aws_ssm_parameter" "eks_iam_role" {
  name = "/unity/account/eks/eks_iam_role"
}

data "aws_ssm_parameter" "eks_ami" {
  name = "/unity/account/ami/eksClusterAmi"
}

variable "tags" {
  type = map(string)
}

variable "name" {
  type = string
}

variable "nodegroups" {
  description = "The nodegroups configuration"

  type = map(object({
    create_iam_role             = optional(bool)
    iam_role_arn                = optional(string)
    ami_id                      = optional(string)
    min_size                    = optional(number)
    max_size                    = optional(number)
    desired_size                = optional(number)
    instance_types              = optional(list(string))
    capacity_type               = optional(string)
    enable_bootstrap_user_data  = optional(bool)
  }))

  default = {}
}

variable "cluster_version" {
  type = string
  default = "1.27"
}


locals {
  common_tags = {}
  cluster_name = var.name
  subnet_map = jsondecode(data.aws_ssm_parameter.subnet_list.value)
  ami = data.aws_ssm_parameter.eks_ami.value
  iam_arn = data.aws_ssm_parameter.eks_iam_node_role.value
  mergednodegroups = {for name, ng in var.nodegroups:
      name => {
        create_iam_role = false
        min_size = ng.min_size != null ? ng.min_size : 1
        max_size = ng.max_size != null ? ng.max_size : 10
        desired_size = ng.desired_size != null ? ng.desired_size : 3
        ami_id = ng.ami_id != null ? ng.ami_id : data.aws_ssm_parameter.eks_ami.value
        instance_types = ng.instance_types != null ? ng.instance_types : ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
        capacity_type = ng.capacity_type != null ? ng.capacity_type : "SPOT"
        iam_role_arn = ng.iam_role_arn != null ? ng.iam_role_arn : data.aws_ssm_parameter.eks_iam_node_role.value
        enable_bootstrap_user_data = true
      }
    }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  subnet_ids       = local.subnet_map["private"]

  vpc_id = data.aws_ssm_parameter.vpc_id.value

  cluster_security_group_id = data.aws_ssm_parameter.cluster_sg.value
  create_cluster_security_group = false
  create_node_security_group = false
  create_iam_role = false
  enable_irsa = false
  iam_role_arn = data.aws_ssm_parameter.eks_iam_role.value
  node_security_group_id = data.aws_ssm_parameter.node_sg.value

  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    iam_role_arn              = data.aws_ssm_parameter.eks_iam_node_role.value
  }

  eks_managed_node_groups = local.mergednodegroups
  tags = var.tags
}

resource "aws_launch_template" "node_group_launch_template" {
  image_id = data.aws_ssm_parameter.eks_ami.value
  name = "eks-${local.cluster_name}-nodeGroup-launchTemplate"
  user_data = base64encode(<<EOT
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${local.cluster_name}
  EOT
  )
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name      = "${local.cluster_name} Node Group Node"
      Component = "EKS EC2 Instance"
      Stack     = "EKS EC2 Instance"
    })
  }
}


# TODO: select default node group more intelligently, or remove concept altogether
resource "aws_ssm_parameter" "node_group_default_name" {
  name = "/unity/extensions/eks/${local.cluster_name}/nodeGroups/default/name"
  type = "String"
  # Get name of first nodegroup in nodegroup map variable
  value =  element(keys(local.mergednodegroups), 0)
  # Get first nodegroup name from keys of node group variable and use it to
  # value = split(":", aws_eks_node_group.node_groups[keys(var.node_groups)[0]].id)[0]
}

resource "aws_ssm_parameter" "node_group_default_launch_template_name" {
  name = "/unity/extensions/eks/${local.cluster_name}/nodeGroups/default/launchTemplateName"
  type = "String"
  value = aws_launch_template.node_group_launch_template.name
}

#module "irsa-ebs-csi" {
#  source  = "terraform-aws-modules/iam/aws//modules/iamable-role-with-oidc"
#  version = "4.7.0"
#
#  create_role                   = true
#  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
#  provider_url                  = module.eks.oidc_provider
#  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
#  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
#}
#
#resource "aws_eks_addon" "ebs-csi" {
#  cluster_name             = module.eks.cluster_name
#  addon_name               = "aws-ebs-csi-driver"
#  addon_version            = "v1.20.0-eksbuild.1"
#  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
#  tags = {
#    "eks_addon" = "ebs-csi"
#    "terraform" = "true"
#  }
#}
