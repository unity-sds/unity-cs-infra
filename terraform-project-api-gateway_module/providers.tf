terraform {
  backend "s3" {
    bucket = "unity-cs-tf-state-${var.venue}"
    key    = "project_api_gateway_tf_state"
    region = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}