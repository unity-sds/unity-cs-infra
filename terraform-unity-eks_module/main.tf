provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      ServiceArea = "UCS"
      Project     = "Nightly"
    }
  }
}
variable "vpc_id" {
  type = string
}
variable "subnets" {
  type = map(list(string))
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.cluster.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority)
#  token                  = data.aws_eks_cluster_auth.cluster.token
#}

data "aws_availability_zones" "available" {
}

locals {
  cluster_name = "my-cluster"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"
  subnet_ids       = var.subnets.private

  vpc_id = var.vpc_id

  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      ami_type = "AL2_x86_64"
      ami_id = "ami-00c008cd43492a617"
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }
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
