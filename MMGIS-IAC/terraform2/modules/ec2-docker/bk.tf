locals {
    block_device_path = "/dev/sdh"
}

data "aws_iam_role" "existing_role" {
  name = "Unity-CS_Service_Role"
}

# Get "golden" MCP AMI to use for the instance.
data "aws_ssm_parameter" "mmgis_ami_id" {
  name = "/mcp/amis/ubuntu2004-cset"
}

data "aws_ssm_parameter" "subnet_id" {
  name = "/unity/account/network/publicsubnet1"
}

resource "aws_security_group" "mmgis-sg" {
  name        = "${var.venue}-${var.project}-mmgis-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  tags = {
    Name = "${var.venue}-${var.project}-mmgis-sg"
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["137.78.80.226/32"]  # temporary for me
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "unity_mmgis_instance_profile" {
  name = "${var.venue}-${var.project}-mmgis-ip"

  role = data.aws_iam_role.existing_role.name

  tags = {
    Name = "${var.venue}-${var.project}-mmgis-ip"
  }
}
 
resource "aws_ebs_volume" "persistent" {
    availability_zone = aws_instance.unity_mmgis_instance.availability_zone
    size = var.persistent_volume_size_gb
}

resource "aws_volume_attachment" "persistent" {
    device_name = local.block_device_path
    volume_id = aws_ebs_volume.persistent.id
    instance_id = aws_instance.unity_mmgis_instance.id
}

# =================== EC2 INSTANCE FOR MMGIS ================
#
resource "aws_instance" "unity_mmgis_instance" {
  ami           = data.aws_ssm_parameter.mmgis_ami_id.value
  instance_type = var.instance_type

  tags = {
    Name = "unity-mmgis-galen-instance-tf"
  }

  vpc_security_group_ids = [ aws_security_group.mmgis-sg.id ]

  subnet_id = data.aws_ssm_parameter.subnet_id.value

  iam_instance_profile = aws_iam_instance_profile.unity_mmgis_instance_profile.name

  user_data = <<EOF
#!/bin/bash

# Update the package repo
sudo apt-get update

# Install the SSM Agent
sudo snap install amazon-ssm-agent --classic

# Start the SSM Agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

EOF
  
}