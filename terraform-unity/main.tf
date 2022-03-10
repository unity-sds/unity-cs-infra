terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
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
  backend "s3" { 
    bucket = "unity-cs-infra"
    key    = "build/state"
    region = "us-east-1"
  }
}

provider "aws" {
  profile = "saml-pub"
}

resource "aws_vpc" "unity-infra-env" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "unity-infra-env"
  }
}

resource "aws_eip" "ip-infra-env" {
  instance = "${aws_instance.unity-ec2-instance.id}"
  vpc      = true
}

resource "aws_instance" "unity-ec2-instance" {
  ami = "${var.ami_id}"
  instance_type = "t3.xlarge"
  key_name = "${var.ami_key_pair_name}"
  #security_groups = ["${aws_security_group.ingress-all-test.id}"]
  vpc_security_group_ids = [aws_security_group.ingress-all-test.id]
  tags = {
    Name = "${var.ami_name}"
  }
  subnet_id = "${aws_subnet.subnet-uno.id}"
}

