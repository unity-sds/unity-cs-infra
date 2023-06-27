terraform {
  required_version = ">= 0.14.9"

  backend "s3" {
    bucket = "unity-cs-tf-state-sips"
    key    = "venue_state"
    region = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        runner = "github"
      },
    )
  }
}


variable "default_tags" {
  default = {
    Owner   = "Unity CS"
    Project = "Unity CS"
  }
  description = "Default Tags"
  type        = map(string)
}

data "aws_caller_identity" "current" {}

resource "aws_ssm_parameter" "unity-venue" {
  name  = "/unity/core/venue"
  type  = "String"
  value = var.venue
}

resource "aws_ssm_parameter" "unity-project" {
  name  = "/unity/core/project"
  type  = "String"
  value = var.project
}

resource "aws_ssm_parameter" "eks-instance-role" {
  name = "/unity/account/roles/eksInstanceRoleArn"
  type = "String"
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Unity-UCS-Development-EKSNodeRole"
}

resource "aws_ssm_parameter" "eks-service-role" {
  name = "/unity/account/roles/eksServiceRoleArn"
  type = "String"
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Unity-UCS-Development-EKSClusterS3-Role"
}

data "aws_ssm_parameter" "mcp-eks-ami" {
  name = "/mcp/amis/aml2-eks"
}

resource "aws_ssm_parameter" "eks-cluster-ami" {
    name = "/unity/account/ami/eksClusterAmi"
    type = "String"
    value = data.aws_ssm_parameter.mcp-eks-ami.value
}

locals {
  ssm_parameters_map = { for param in var.ssm_parameters : param.name => param }
}


resource "aws_ssm_parameter" "example" {
  for_each = local.ssm_parameters_map

  name  = each.key
  type  = each.value.type
  value = each.value.value
}
