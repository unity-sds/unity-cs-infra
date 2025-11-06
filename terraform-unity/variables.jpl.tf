#variable "ami_name" { default = "unity-github-runner" }
#variable "ami_id" { default = "ami-04505e74c0741db8d" }
#variable "ami_key_pair_name" { default = "barber-unity-pair" }

variable "ami_name" { default = "unity-ubuntu" }
variable "ami_id" { default = "ami-00f46ccd1cbfb363e" }
#variable "ami_id" { default = "ami-04505e74c0741db8d" }
variable "ami_key_pair_name" { default = "unity-cs-smolensk" }
variable "vpc_id" { default = "vpc-0fd177185e450d73d" }

data "aws_vpc" "unity-test-env" {
  id         = var.vpc_id
  cidr_block = "10.0.0.0/16"
}

