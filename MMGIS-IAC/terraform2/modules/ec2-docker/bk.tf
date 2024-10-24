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
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: CHANGE ME!
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: CHANGE ME!
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
    Name = "${var.venue}-${var.project}-mmgis"
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

# Filesystem code is over

# Now we install docker and docker-compose.
# See:
# https://docs.docker.com/engine/install/ubuntu/
#
# Uninstall all conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker & docker compose
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker and add user to docker group
systemctl start docker.service
usermod -a -G docker ubuntu

# Put the docker-compose.yml file at the root of our persistent volume
cat > /home/ubuntu/docker-compose.yml <<-TEMPLATE
${var.docker_compose_str}
TEMPLATE

# Write the systemd service that manages us bringing up the service
cat > /etc/systemd/system/mmgis.service <<-TEMPLATE
[Unit]
Description=${var.description}
After=${var.systemd_after_stage}
[Service]
Type=simple
User=ubuntu
ExecStart=sudo /usr/bin/docker compose -f /home/ubuntu/docker-compose.yml up
Restart=on-failure
[Install]
WantedBy=multi-user.target
TEMPLATE

# Start the service.
systemctl start mmgis


EOF
  
}