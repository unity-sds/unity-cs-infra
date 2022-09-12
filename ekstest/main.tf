terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }

  required_version = ">= 0.14.9"

}

provider "aws" {
  region  = "us-west-2"

  # default_tags {
#    tags = {
#      ExampleDefaultTag = "ExampleDefaultValue"
#    }
#  }
}

#provider "kubernetes" {
#  host                   = module.eks.cluster_endpoint
#  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#
#  exec {
#    api_version = "client.authentication.k8s.io/v1beta1"
#    command     = "aws"
#    # This requires the awscli to be installed locally where Terraform is executed
#    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
#  }
#}

locals {
  name   = "ex-${replace(basename(path.cwd), "_", "-")}"
  region = "eu-west-1"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = local.name
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }


  create_cloudwatch_log_group = false
  create_node_security_group = false
  create_cluster_security_group = false
  create_cluster_primary_security_group_tags = false

  # Encryption key
  create_kms_key = false
#  cluster_encryption_config = [{
#    resources = ["secrets"]
#  }]
#  kms_key_deletion_window_in_days = 7
#  enable_kms_key_rotation         = true

  create_iam_role = false

  iam_role_arn = "arn:aws:iam::237868187491:role/Unity-UCS-development-EKSClusterRole"
  vpc_id                   = "vpc-0106218dbddd3a753"
  subnet_ids               = ["subnet-059bc4f467275b59d", "subnet-0ebdd997cc3ebe58d"]
  cluster_security_group_id = "sg-09bd8de0af1c3c99a"


  #control_plane_subnet_ids = module.vpc.intra_subnets

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_ntp_ipv4_cidr_block = ["169.254.169.123/32"]
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Self Managed Node Group(s)
#  self_managed_node_group_defaults = {
#    vpc_security_group_ids       = [aws_security_group.additional.id]
#    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
#  }

  self_managed_node_groups = {
#    spot = {
#      instance_type = "m5.large"
#      instance_market_options = {
#        market_type = "spot"
#      }
#
#      pre_bootstrap_user_data = <<-EOT
#      echo "foo"
#      export FOO=bar
#      EOT
#
#      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
#
#      post_bootstrap_user_data = <<-EOT
#      cd /tmp
#      sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
#      sudo systemctl enable amazon-ssm-agent
#      sudo systemctl start amazon-ssm-agent
#      EOT
#    }
  }

  # EKS Managed Node Group(s)
#  eks_managed_node_group_defaults = {
#    ami_type       = "AL2_x86_64"
#    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
#
#    attach_cluster_primary_security_group = true
#    vpc_security_group_ids                = [aws_security_group.additional.id]
#  }

  eks_managed_node_groups = {
#    blue = {}
#    green = {
#      min_size     = 1
#      max_size     = 10
#      desired_size = 1
#
#      instance_types = ["t3.large"]
#      capacity_type  = "SPOT"
#      labels = {
#        Environment = "test"
#        GithubRepo  = "terraform-aws-eks"
#        GithubOrg   = "terraform-aws-modules"
#      }
#
#      taints = {
#        dedicated = {
#          key    = "dedicated"
#          value  = "gpuGroup"
#          effect = "NO_SCHEDULE"
#        }
#      }
#
#      update_config = {
#        max_unavailable_percentage = 50 # or set `max_unavailable`
#      }
#
#      tags = {
#        ExtraTag = "example"
#      }
#    }
  }

  # Fargate Profile(s)
#  fargate_profiles = {
#    default = {
#      name = "default"
#      selectors = [
#        {
#          namespace = "kube-system"
#          labels = {
#            k8s-app = "kube-dns"
#          }
#        },
#        {
#          namespace = "default"
#        }
#      ]
#
#      tags = {
#        Owner = "test"
#      }
#
#      timeouts = {
#        create = "20m"
#        delete = "20m"
#      }
#    }
#  }

  # OIDC Identity provider
#  cluster_identity_providers = {
#    sts = {
#      client_id = "sts.amazonaws.com"
#    }
#  }

  # aws-auth configmap
  manage_aws_auth_configmap = false

#  aws_auth_node_iam_role_arns_non_windows = [
#    module.eks_managed_node_group.iam_role_arn,
#    module.self_managed_node_group.iam_role_arn,
#  ]
#  aws_auth_fargate_profile_pod_execution_role_arns = [
#    module.fargate_profile.fargate_profile_pod_execution_role_arn
#  ]

#  aws_auth_roles = [
#    {
#      rolearn  = "arn:aws:iam::66666666666:role/role1"
#      username = "role1"
#      groups   = ["system:masters"]
#    },
#  ]
#
#  aws_auth_users = [
#    {
#      userarn  = "arn:aws:iam::66666666666:user/user1"
#      username = "user1"
#      groups   = ["system:masters"]
#    },
#    {
#      userarn  = "arn:aws:iam::66666666666:user/user2"
#      username = "user2"
#      groups   = ["system:masters"]
#    },
#  ]
#
#  aws_auth_accounts = [
#    "777777777777",
#    "888888888888",
#  ]

 # tags = local.tags
}

################################################################################
# Sub-Module Usage on Existing/Separate Cluster
################################################################################

#module "eks_managed_node_group" {
#  source = "../../modules/eks-managed-node-group"
#
#  name            = "separate-eks-mng"
#  cluster_name    = module.eks.cluster_id
#  cluster_version = module.eks.cluster_version
#
#  vpc_id                            = module.vpc.vpc_id
#  subnet_ids                        = module.vpc.private_subnets
#  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
#  vpc_security_group_ids = [
#    module.eks.cluster_security_group_id,
#  ]
#
#  tags = merge(local.tags, { Separate = "eks-managed-node-group" })
#}
#
#module "self_managed_node_group" {
#  source = "../../modules/self-managed-node-group"
#
#  name                = "separate-self-mng"
#  cluster_name        = module.eks.cluster_id
#  cluster_version     = module.eks.cluster_version
#  cluster_endpoint    = module.eks.cluster_endpoint
#  cluster_auth_base64 = module.eks.cluster_certificate_authority_data
#
#  instance_type = "m5.large"
#
#  vpc_id     = module.vpc.vpc_id
#  subnet_ids = module.vpc.private_subnets
#  vpc_security_group_ids = [
#    module.eks.cluster_primary_security_group_id,
#    module.eks.cluster_security_group_id,
#  ]
#
#  use_default_tags = true
#
#  tags = merge(local.tags, { Separate = "self-managed-node-group" })
#}
#
#module "fargate_profile" {
#  source = "../../modules/fargate-profile"
#
#  name         = "separate-fargate-profile"
#  cluster_name = module.eks.cluster_id
#
#  subnet_ids = module.vpc.private_subnets
#  selectors = [{
#    namespace = "kube-system"
#  }]
#
#  tags = merge(local.tags, { Separate = "fargate-profile" })
#}

################################################################################
# Disabled creation
################################################################################


#module "disabled_fargate_profile" {
#  source = "../../modules/fargate-profile"
#
#  create = false
#}
#
#module "disabled_eks_managed_node_group" {
#  source = "../../modules/eks-managed-node-group"
#
#  create = false
#}
#
#module "disabled_self_managed_node_group" {
#  source = "../../modules/self-managed-node-group"
#
#  create = false
#}
