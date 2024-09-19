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

  user_data = file("./modules/ec2-docker/add-mmgis.sh")
}