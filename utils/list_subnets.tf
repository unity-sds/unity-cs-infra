# ============================================================================
# This Terraform script, lists the subnets,
# grouped by AZ for the current AWS account.
#
#  TO RUN:
#   1) log into Kion to get the Short-term access keys.
#   2) paste export statements of access keys into terminal.
#   3) cd into this directory (with the list_subnets.tf file)
#   4) terraform init
#   5) terraform apply
#
# ============================================================================

provider "aws" {
  region = "us-west-2"  # Change this to your desired AWS region
}

data "aws_vpcs" "existing_vpcs" {}

locals {
  azs = toset(["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"])
}

data "aws_subnets" "public" {
   filter {
    name   = "vpc-id"
    values = data.aws_vpcs.existing_vpcs.ids 
  }
  filter {
    name = "tag:Name"
    values = ["Unity-Dev-Pub-Subnet*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = data.aws_vpcs.existing_vpcs.ids
  }
  filter {
   name = "tag:Name"
   values = ["Unity-Dev-Priv-Subnet*"]
  }
}

locals {
  private_subnet_data = [
    for subnet_id in data.aws_subnets.private.ids : {
      id = subnet_id
    }
  ]
  public_subnet_data = [
    for subnet_id in data.aws_subnets.public.ids : {
      id = subnet_id
    }
  ]
}

data "aws_subnet" "private_subnet_list" {
  count = length(local.private_subnet_data)
  id = local.private_subnet_data[count.index].id
}

data "aws_subnet" "public_subnet_list" {
  count = length(local.public_subnet_data)
  id = local.public_subnet_data[count.index].id
}


locals {
  az_subnet_ids = {
    for az in local.azs : az => {
      private_subnets  = [
        for subnet in data.aws_subnet.private_subnet_list :
        subnet.id if subnet.availability_zone == az
      ]
      public_subnets  = [
          for subnet in data.aws_subnet.public_subnet_list :
          subnet.id if subnet.availability_zone == az
      ]
    }
  }
}

output "unity_subnets" {
  value = local.az_subnet_ids
}


