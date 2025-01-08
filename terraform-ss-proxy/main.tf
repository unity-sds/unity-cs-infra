# Define the AWS provider
provider "aws" {
  profile = "mcp-venue-dev-ss"
  region  = "us-west-2"
}

# Get the AMI ID from SSM Parameter Store
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/mcp/amis/ubuntu2004-cset"
}

# Get VPC ID from SSM Parameter Store
data "aws_ssm_parameter" "vpc_id" {
  name = "/unity/shared-services/network/vpc_id"
}

# Get Private Subnet ID from SSM Parameter Store
data "aws_ssm_parameter" "private_subnet_id" {
  name = "/unity/shared-services/network/privatesubnet2"
}

# Get existing security group
data "aws_security_group" "httpd_sg" {
  name = "shared-services-httpd-sg"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
}

# Get venue from SSM Parameter Store
data "aws_ssm_parameter" "venue" {
  name = "/unity/account/venue"
}

# Create EC2 instance
resource "aws_instance" "httpd_instance" {
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t3.large"
  
  subnet_id                   = data.aws_ssm_parameter.private_subnet_id.value
  vpc_security_group_ids     = [data.aws_security_group.httpd_sg.id]
  iam_instance_profile       = "U-CS_Service_Role"
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              sudo su - ubuntu << 'USERDATA'
              echo "Starting Apache installation and configuration..."

              # Clone unity-cs-infra repository
              echo "Cloning unity-cs-infra repository..."
              cd /home/ubuntu
              git clone https://github.com/unity-sds/unity-cs-infra.git

              # Update package lists
              echo "Updating package lists..."
              sudo apt update

              # Install Apache2, OpenIDC module, and AWS CLI
              echo "Installing Apache2, OpenIDC module, and AWS CLI..."
              sudo DEBIAN_FRONTEND=noninteractive apt install -y apache2 libapache2-mod-auth-openidc awscli

              # Enable Apache modules
              echo "Enabling Apache modules..."
              sudo a2enmod http2
              sudo a2enmod headers
              sudo a2enmod proxy
              sudo a2enmod proxy_html
              sudo a2enmod proxy_http
              sudo a2enmod proxy_wstunnel
              sudo a2enmod ssl
              sudo a2enmod rewrite
              sudo a2enmod auth_openidc

              # Generate self-signed SSL certificate
              echo "Generating self-signed SSL certificate..."
              sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout /etc/ssl/private/apache-selfsigned.key \
                -out /etc/ssl/certs/apache-selfsigned.crt \
                -subj "/C=US/ST=CA/L=LA/O=Unity/OU=CS/CN=shared-services-httpd-unity-test/emailAddress=test@test.com"

              # Restart Apache to apply changes
              echo "Restarting Apache..."
              sudo systemctl restart apache2

              # Create and set permissions for sync log file
              echo "Setting up sync log file..."
              sudo touch /var/log/sync_apache_config.log
              sudo chown ubuntu:ubuntu /var/log/sync_apache_config.log
              sudo chmod 644 /var/log/sync_apache_config.log

              # Set up cron job with PATH
              echo "Setting up cron job..."
              SYSTEM_PATH=$(echo $PATH)
              (crontab -l 2>/dev/null; echo "PATH=$SYSTEM_PATH") | crontab -
              (crontab -l 2>/dev/null; echo "* * * * * ~/unity-cs-infra/terraform-ss-proxy/sync_apache_config.sh >> /var/log/sync_apache_config.log 2>&1") | crontab -

              # Get venue from SSM and download Apache config
              echo "Downloading Apache configuration..."
              VENUE=$(aws ssm get-parameter --name "/unity/account/venue" --query "Parameter.Value" --output text)
              sudo aws s3 cp "s3://ucs-shared-services-apache-config-$VENUE/unity-cs.conf" /etc/apache2/sites-enabled/

              # Set proper permissions
              sudo chown root:root /etc/apache2/sites-enabled/unity-cs.conf
              sudo chmod 644 /etc/apache2/sites-enabled/unity-cs.conf

              echo "Installation and configuration complete!"
              USERDATA
              EOF

  tags = {
    #TODO: change this to the actual name
    Name = "shared-services-httpd2"
  }
}
