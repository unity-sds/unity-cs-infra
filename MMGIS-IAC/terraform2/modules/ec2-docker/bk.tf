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


  # user_data = file("./modules/ec2-docker/add-mmgis.sh")

  user_data = <<EOF
#!/bin/bash

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
chown ec2-user:ec2-user $DEST
chmod 0755 $DEST

# Filesystem code is over

# Now we install docker and docker-compose.
# See:
# https://docs.docker.com/engine/install/ubuntu/
#
# Uninstall all conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
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


# Start Docker
systemctl start docker.service
usermod -a -G docker ubuntu # Add your user to the docker group

#
# DON'T NEED PYTHON??
#
#yum install -y python3-pip
#python3 -m pip install docker-compose

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
  
}