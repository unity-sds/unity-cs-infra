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

# Create ALB security group
# TODO: REMOVE this ALB securty group. 
# Use ucs-httpd-alb-sec-group
resource "aws_security_group" "alb_sg" {
  #TODO: change this to the actual name
  name        = "ucs-httpd-alb-sec-group2"
  description = "Security group for shared services ALB"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  # Incoming rules for ALB
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from anywhere"
  }

  # Outgoing rule - allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    #TODO: change this to the actual name
    Name = "ucs-httpd-alb-sec-group2"
  }
}

# Create security group for HTTPD instance
resource "aws_security_group" "httpd_sg" {
  #TODO: change this to the actual name
  name        = "shared-services-httpd-sg2"
  description = "Security group for shared services HTTPD"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  # Incoming rule for HTTPS
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Outgoing rule - allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    #TODO: change this to the actual name
    Name = "shared-services-httpd-sg2"
  }
}

# Create EC2 instance
resource "aws_instance" "httpd_instance" {
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t3.large"
  
  subnet_id                   = data.aws_ssm_parameter.private_subnet_id.value
  vpc_security_group_ids     = [aws_security_group.httpd_sg.id]
  iam_instance_profile       = "MCP-SSM-CloudWatch"
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              sudo su - ubuntu << 'USERDATA'
              echo "Starting Apache installation and configuration..."

              # Update package lists
              echo "Updating package lists..."
              sudo apt update

              # Install Apache2 and OpenIDC module
              echo "Installing Apache2 and OpenIDC module..."
              sudo DEBIAN_FRONTEND=noninteractive apt install -y apache2
              sudo DEBIAN_FRONTEND=noninteractive apt-get install -y libapache2-mod-auth-openidc

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

              echo "Installation and configuration complete!"
              USERDATA
              EOF

  tags = {
    #TODO: change this to the actual name
    Name = "shared-services-httpd2"
  }
}
