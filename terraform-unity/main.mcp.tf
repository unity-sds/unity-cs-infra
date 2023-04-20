terraform {
  required_version = ">= 0.14.9"

  backend "s3" {
    bucket = "unity-cs-tf-state-dev"
    key    = "tf_state"
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

