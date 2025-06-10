#!/bin/bash

# Parse command line arguments
TERRAFORM_ONLY=false
DESTROY_TERRAFORM=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --terraform-only)
      TERRAFORM_ONLY=true
      shift
      ;;
    --destroy-terraform)
      DESTROY_TERRAFORM=true
      TERRAFORM_ONLY=true
      shift
      ;;
    *)
      echo "Unknown option $1"
      echo "Usage: $0 [--terraform-only] [--destroy-terraform]"
      echo "  --terraform-only     Only run Terraform infrastructure setup"
      echo "  --destroy-terraform  Destroy Terraform infrastructure (implies --terraform-only)"
      exit 1
      ;;
  esac
done


# Get environment from SSM
export ENV_SSM_PARAM="/unity/account/venue"
ENVIRONMENT=$(aws ssm get-parameter --name ${ENV_SSM_PARAM} --query "Parameter.Value" --output text)

# Default configuration variables (can be overridden with environment variables)
S3_BUCKET_NAME="${S3_BUCKET_NAME:-ucs-shared-services-apache-config-${ENVIRONMENT}}"
PERMISSION_BOUNDARY_ARN="arn:aws:iam::237868187491:policy/mcp-tenantOperator-AMI-APIG"
AWS_REGION="${AWS_REGION:-us-west-2}"
APACHE_HOST="${APACHE_HOST:-www.dev.mdps.mcp.nasa.gov}"
APACHE_PORT="${APACHE_PORT:-4443}"
RELOAD_DELAY="${RELOAD_DELAY:-15}"
OIDC_CLIENT_ID="${OIDC_CLIENT_ID:-ee3duo3i707h93vki01ivja8o}"
COGNITO_USER_POOL_ID="${COGNITO_USER_POOL_ID:-us-west-2_yaOw3yj0z}"

echo "Using configuration:"
echo "  S3_BUCKET_NAME: $S3_BUCKET_NAME"
echo "  PERMISSION_BOUNDARY_ARN: $PERMISSION_BOUNDARY_ARN"
echo "  AWS_REGION: $AWS_REGION"
echo "  APACHE_HOST: $APACHE_HOST"
echo "  APACHE_PORT: $APACHE_PORT"
echo "  DEBOUNCE_DELAY: $DEBOUNCE_DELAY"
echo ""

if [ "$DESTROY_TERRAFORM" = true ]; then
    echo "Running in Terraform destroy mode..."
elif [ "$TERRAFORM_ONLY" = true ]; then
    echo "Running in Terraform-only mode..."
else
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo "Terraform not found. Installing Terraform..."
        
        # Linux
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    else
        echo "Terraform is already installed: $(terraform version)"
    fi

    # Install Apache2, but get a newer version if at least 2.4.53 is not available
    echo "Checking Apache version requirements..."
    
    # First update package list
    sudo apt-get update
    
    # Check available version in apt
    APT_VERSION=$(apt-cache policy apache2 | grep Candidate | awk '{print $2}' | cut -d'-' -f1 | cut -d':' -f2)
    echo "Available Apache version in apt: $APT_VERSION"
    
    # Function to compare versions
    version_ge() {
        [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
    }
    
    REQUIRED_VERSION="2.4.53"
    
    # Check if apt version meets requirements
    if version_ge "$APT_VERSION" "$REQUIRED_VERSION"; then
        echo "Apt version ($APT_VERSION) meets requirements (>= $REQUIRED_VERSION). Installing from apt..."
        sudo apt-get install -y apache2
    else
        echo "Apt version ($APT_VERSION) does not meet requirements (>= $REQUIRED_VERSION)."
        echo "Installing Apache from source..."
        
        # Install build dependencies
        sudo apt-get install -y build-essential libssl-dev libexpat1-dev libpcre3-dev libapr1-dev libaprutil1-dev
        
        # Create temp directory for build
        BUILD_DIR=$(mktemp -d)
        cd "$BUILD_DIR"
        
        # Get latest Apache version
        echo "Downloading latest Apache source..."
        LATEST_VERSION=$(curl -s https://downloads.apache.org/httpd/ | grep -oP 'httpd-\K[0-9.]+(?=\.tar\.gz)' | sort -V | tail -1)
        echo "Latest Apache version available: $LATEST_VERSION"
        
        if [ -z "$LATEST_VERSION" ]; then
            echo "Error: Could not determine latest Apache version"
            exit 1
        fi
        
        # Download and extract
        wget "https://downloads.apache.org/httpd/httpd-${LATEST_VERSION}.tar.gz"
        tar -xzf "httpd-${LATEST_VERSION}.tar.gz"
        cd "httpd-${LATEST_VERSION}"
        
        # Configure, compile and install
        ./configure --prefix=/usr/local/apache2 \
                    --enable-ssl \
                    --enable-so \
                    --enable-rewrite \
                    --enable-cgi \
                    --enable-cgid \
                    --enable-headers \
                    --enable-ratelimit \
                    --with-mpm=prefork
        
        make -j$(nproc)
        sudo make install
        
        # Create systemd service file for custom Apache installation
        sudo tee /etc/systemd/system/apache2.service > /dev/null <<EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/apache2/bin/apachectl start
ExecStop=/usr/local/apache2/bin/apachectl stop
ExecReload=/usr/local/apache2/bin/apachectl graceful
PIDFile=/usr/local/apache2/logs/httpd.pid
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
        
        # Create necessary directories and symlinks for compatibility
        sudo mkdir -p /etc/apache2/sites-enabled
        sudo mkdir -p /etc/apache2/venues.d
        sudo mkdir -p /var/www/html
        sudo mkdir -p /usr/lib/cgi-bin
        
        # Create symlinks for commands
        sudo ln -sf /usr/local/apache2/bin/apachectl /usr/sbin/apachectl
        sudo ln -sf /usr/local/apache2/bin/httpd /usr/sbin/apache2
        
        # Create a2enmod script for module management
        sudo tee /usr/sbin/a2enmod > /dev/null <<'SCRIPT'
#!/bin/bash
MODULE=$1
if [ -z "$MODULE" ]; then
    echo "Usage: a2enmod <module>"
    exit 1
fi

# Enable module in httpd.conf
CONF="/usr/local/apache2/conf/httpd.conf"
case $MODULE in
    rewrite|ssl|headers|cgi|cgid|ratelimit)
        sudo sed -i "s/^#LoadModule ${MODULE}_module/LoadModule ${MODULE}_module/" "$CONF"
        echo "Module $MODULE enabled"
        ;;
    *)
        echo "Module $MODULE not recognized"
        ;;
esac
SCRIPT
        sudo chmod +x /usr/sbin/a2enmod
        
        # Update Apache config to include sites-enabled
        echo "Include /etc/apache2/sites-enabled/*.conf" | sudo tee -a /usr/local/apache2/conf/httpd.conf
        
        # Enable and start service
        sudo systemctl daemon-reload
        sudo systemctl enable apache2
        
        # Clean up
        cd /
        rm -rf "$BUILD_DIR"
        
        echo "Apache ${LATEST_VERSION} installed from source successfully"
    fi
fi

if [ "$TERRAFORM_ONLY" = false ]; then
    # Enable Apache2 modules
    sudo a2enmod rewrite cgid ratelimit ssl headers

    # Prepare ratelimit path
    sudo mkdir -p /var/lib/apache2/ratelimit
    sudo chown www-data:www-data /var/lib/apache2/ratelimit

    # Add Config
    sudo cp unity-cs-main.conf /etc/apache2/sites-enabled/unity-cs-main.conf

    # Update with system parameters
    # First lookup the client secret
    echo "Looking up Cognito client secret..."
    CLIENT_SECRET=$(aws cognito-idp describe-user-pool-client \
      --user-pool-id ${COGNITO_USER_POOL_ID} \
      --client-id ${OIDC_CLIENT_ID} \
      --region ${AWS_REGION} \
      --query 'UserPoolClient.ClientSecret' \
      --output text)
    
    if [ -z "$CLIENT_SECRET" ]; then
      echo "Error: Could not retrieve Cognito client secret. Check your credentials and permissions."
      exit 1
    else
      echo "Successfully retrieved Cognito client secret."
    fi
    
    # Update the configuration with the pool ID and client secret
    sudo sed -i "s/\${COGNITO_POOL_ID}/${COGNITO_USER_POOL_ID}/" /etc/apache2/sites-enabled/unity-cs-main.conf
    sudo sed -i "s/\${OIDC_CLIENT_ID}/${OIDC_CLIENT_ID}/" /etc/apache2/sites-enabled/unity-cs-main.conf
    sudo sed -i "s/\${OIDC_CLIENT_SECRET}/${CLIENT_SECRET}/" /etc/apache2/sites-enabled/unity-cs-main.conf
    sudo sed -i "s/\${PORT_NUM}/${APACHE_PORT}/" /etc/apache2/sites-enabled/unity-cs-main.conf

    # Remove the default
    sudo rm /etc/apache2/sites-enabled/000-default.conf

    # Generate a cert
    # Generate certificate and key with predefined values to avoid prompts
    sudo mkdir -p /etc/ssl/certs/
    sudo mkdir -p /etc/ssl/private/
    sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout /etc/ssl/private/apache-selfsigned.key \
        -out /etc/ssl/certs/apache-selfsigned.crt \
        -subj "/C=US/ST=CA/L=Pasadena/O=MDPS/OU=IT/CN=localhost"

    # Set proper permissions
    echo "Setting permissions..."
    sudo chmod 600 /etc/ssl/private/apache-selfsigned.key
    sudo chmod 644 /etc/ssl/certs/apache-selfsigned.crt

    # Create remove default index.html
    sudo rm /var/www/html/index.html

    # Prepare CGI Script
    sudo mkdir -p /etc/apache2/venues.d/
    sudo chown www-data:www-data /etc/apache2/venues.d/
    sudo cp reload-apache.cgi /usr/lib/cgi-bin/reload-apache.cgi
    
    # Replace S3 bucket placeholder in CGI script
    sudo sed -i "s#REPLACE_WITH_S3_BUCKET_NAME#${S3_BUCKET_NAME}#g" /usr/lib/cgi-bin/reload-apache.cgi
    
    # Replace environment placeholder in CGI script
    sudo sed -i "s#REPLACE_WITH_ENVIRONMENT_NAME#${ENVIRONMENT}#g" /usr/lib/cgi-bin/reload-apache.cgi
    
    sudo chown www-data:www-data /usr/lib/cgi-bin/reload-apache.cgi
    sudo chmod 755 /usr/lib/cgi-bin/reload-apache.cgi

    # Update sudoers
    # Using tee to append to sudoers to handle permissions, and ensuring lines are added only once.
    if ! sudo grep -q "www-data ALL=(ALL) NOPASSWD: /usr/sbin/apachectl configtest" /etc/sudoers; then
      echo "www-data ALL=(ALL) NOPASSWD: /usr/sbin/apachectl configtest" | sudo tee -a /etc/sudoers
    fi

    if ! sudo grep -q "www-data ALL=(ALL) NOPASSWD: /usr/sbin/apachectl graceful" /etc/sudoers; then
      echo "www-data ALL=(ALL) NOPASSWD: /usr/sbin/apachectl graceful" | sudo tee -a /etc/sudoers
    fi

    echo "Apache installation complete."
fi

# Generate a random token for Lambda (needed for both modes, except destroy)
if [ "$TERRAFORM_ONLY" = false ]; then
    SECURE_TOKEN=$(openssl rand -hex 16)
    echo "Generated secure token: ${SECURE_TOKEN}"
    echo "This token will be used for Lambda authentication."

    # Update the unity-cs-main.conf file with the new token
    # The sed command uses a different delimiter (#) to avoid issues if the token contains slashes.
    sudo sed -i "s#REPLACE_WITH_SECURE_TOKEN#${SECURE_TOKEN}#g" /etc/apache2/sites-enabled/unity-cs-main.conf
    echo "Apache configuration updated with secure token."
elif [ "$DESTROY_TERRAFORM" = false ]; then
    # Pull the token from /etc/apache2/sites-enabled/unity-cs-main.conf if it exists
    if [ -f "/etc/apache2/sites-enabled/unity-cs-main.conf" ]; then
        # Extract token from SetEnvIf directive: SetEnvIf X-Reload-Token "^TOKEN_HERE$" valid_token
        SECURE_TOKEN=$(sudo grep -oP 'SetEnvIf X-Reload-Token "\^\K[^$]+' /etc/apache2/sites-enabled/unity-cs-main.conf 2>/dev/null || echo "")
        if [ -z "$SECURE_TOKEN" ]; then
            echo "Error: Could not extract token from existing Apache config."
            echo "Looking for: SetEnvIf X-Reload-Token \"^TOKEN\$\" valid_token"
            exit 1
        else
            echo "Using existing token from Apache configuration: ${SECURE_TOKEN}"
        fi
    else
        echo "Apache config not found, must run full install."
        exit 1
    fi
fi

#Make sure apache is reloaded (in case we re-run)
sudo apachectl graceful

# Run Terraform
cd "$(dirname "$0")"

# Initialize Terraform
terraform init

if [ "$DESTROY_TERRAFORM" = true ]; then
    echo "Destroying AWS infrastructure with Terraform..."
    terraform destroy -auto-approve \
      -var="s3_bucket_name=${S3_BUCKET_NAME}" \
      -var="permission_boundary_arn=${PERMISSION_BOUNDARY_ARN}" \
      -var="reload_token=dummy" \
      -var="aws_region=${AWS_REGION}" \
      -var="apache_host=${APACHE_HOST}" \
      -var="apache_port=${APACHE_PORT}" \
      -var="debounce_delay=${RELOAD_DELAY}"
    
    echo "AWS infrastructure destruction complete!"
    echo "Lambda function, SQS queue, and related resources have been removed."
else
    echo "Setting up AWS infrastructure with Terraform..."
    terraform apply -auto-approve \
      -var="s3_bucket_name=${S3_BUCKET_NAME}" \
      -var="permission_boundary_arn=${PERMISSION_BOUNDARY_ARN}" \
      -var="reload_token=${SECURE_TOKEN}" \
      -var="aws_region=${AWS_REGION}" \
      -var="apache_host=${APACHE_HOST}" \
      -var="apache_port=${APACHE_PORT}" \
      -var="debounce_delay=${RELOAD_DELAY}"
    
    echo "AWS infrastructure setup complete!"
    echo "Lambda function created and configured to monitor S3 bucket and process via SQS FIFO queue."
fi
