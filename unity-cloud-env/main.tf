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

resource "aws_ssm_parameter" "unity-private-subnets" {
  name  = "/unity/network/subnets/private"
  type  = "StringList"
  value = var.privatesubnets
}

resource "aws_ssm_parameter" "unity-public-subnets" {
  name  = "/unity/network/subnets/public"
  type  = "StringList"
  value = var.publicsubnets
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
