provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      ServiceArea = "UCS"
      Project     = "Nightly"
    }
  }
}



data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

data "aws_availability_zones" "available" {
}

locals {
  cluster_name = "my-cluster"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.25"
  subnet_ids       = [aws_subnet.subnet-uno.id]

  vpc_id = data.aws_vpc.id

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


  write_kubeconfig   = true
  config_output_path = "./"
}
