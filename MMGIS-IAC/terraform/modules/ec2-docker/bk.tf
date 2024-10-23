locals {
    block_device_path = "/dev/sdh"
}

data "aws_iam_role" "existing_role" {
  name = "Unity-CS_Service_Role"
}

data "aws_ssm_parameter" "mmgis_ami_id" {
  name = "/mcp/amis/ubuntu2004-cset"
}

data "aws_ssm_parameter" "subnet_id" {
  name = "/unity/account/network/publicsubnet1"
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  tags = {
    Name = "allow_tls"
  }
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the world; restrict as needed
  }
 
  ingress {
    description = "Allow port 8888"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to the world; restrict as needed
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "unity_mmgis_instance_profile" {
  name = "unity-mmgis-instance-profile-tf"

  role = data.aws_iam_role.existing_role.name

  tags = {
    Name = "unity_mmgis_instance_profile"
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


resource "aws_instance" "unity_mmgis_instance" {
  ami           = data.aws_ssm_parameter.mmgis_ami_id.value
  instance_type = var.instance_type

  tags = {
    Name = "unity-mmgis-instance-tf"
  }

  vpc_security_group_ids = [ aws_security_group.allow_tls.id ]

  subnet_id = data.aws_ssm_parameter.subnet_id.value

  iam_instance_profile = aws_iam_instance_profile.unity_mmgis_instance_profile.name

  user_data = <<EOF
  #!/bin/bash
# From https://gist.github.com/jamesmishra/18ee5d7d053db9958d0e4ccbb37f8e1d
#set -Eeuxo pipefail
# Filesystem code is adapted from:
# https://github.com/GSA/devsecops-example/blob/03067f68ee2765f8477ae84235f7faa1d2f2cb70/terraform/files/attach-data-volume.sh
DEVICE=${local.block_device_path}
DEST=${var.persistent_volume_mount_path}
devpath=$(readlink -f $DEVICE)

if [[ $(file -s $devpath) != *ext4* && -b $devpath ]]; then
    # Filesystem has not been created. Create it!
    mkfs -t ext4 $devpath
fi
# add to fstab if not present
if ! egrep "^$devpath" /etc/fstab; then
  echo "$devpath $DEST ext4 defaults,nofail,noatime,nodiratime,barrier=0,data=writeback 0 2" | tee -a /etc/fstab > /dev/null
fi
mkdir -p $DEST
mount $DEST
chown ubuntu:ubuntu $DEST
chmod 0755 $DEST

# Filesystem code is over
# Now we install docker and docker-compose.
# Adapted from:
# https://gist.github.com/npearce/6f3c7826c7499587f00957fee62f8ee9
#
# Check if Docker is installed
#
if ! command -v docker &> /dev/null; then
echo "Docker not installed. Installing Docker..."

# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sleep 10

echo "Docker installed successfully."
else
echo "Docker already installed [OK]"
fi
systemctl start docker.service
usermod -a -G docker ubuntu
chkconfig docker on
# Install python3-pip
sudo apt update
sudo apt install -y python3-pip
python3 -m pip install docker-compose

# Put the docker-compose.yml file at the root of our persistent volume
cat > $DEST/docker-compose.yml <<-TEMPLATE
${var.docker_compose_str}
TEMPLATE

# Write the systemd service that manages us bringing up the service
cat > /etc/systemd/system/mmgis.service <<-TEMPLATE
[Unit]
Description=${var.description}
After=${var.systemd_after_stage}
[Service]
Type=simple
User=${var.user}
ExecStart=/usr/local/bin/docker-compose -f $DEST/docker-compose.yml up
Restart=on-failure
[Install]
WantedBy=multi-user.target
TEMPLATE

# Start the service.
systemctl start mmgis
EOF

  key_name = "unity-mmgis-key"
}