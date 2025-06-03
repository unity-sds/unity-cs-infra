# Shared Services Proxy Instructions

## Overview

The shared services proxy runs as an EC2 instance with Apache2 as a service. The configuration is maintained as files in an S3 bucket which automatically triggers server configuration updates when files are added, modified, or deleted.

## EC2 Instance Setup

### Instance Requirements

Create an EC2 instance with the following specifications:
- **Instance Type**: `t2.large`
- **Storage**: 12 GB
- **IAM Role**: `U-CS_Service_Role`
- **AMI**: Use the standard Ubuntu AMI as documented in the SSM Parameters
- **Security Groups**: Configure to allow HTTPS traffic on port 4443

### IAM Permissions Required

The EC2 instance's IAM role (`U-CS_Service_Role`) must have the following AWS permissions to run the Terraform infrastructure setup:

**Required AWS Service Permissions:**
- **SQS**: Create and manage FIFO queues (`sqs:CreateQueue`, `sqs:SetQueueAttributes`, `sqs:TagQueue`)
- **Lambda**: Create functions and manage configurations (`lambda:CreateFunction`, `lambda:UpdateFunctionCode`, `lambda:UpdateFunctionConfiguration`, `lambda:AddPermission`, `lambda:CreateEventSourceMapping`)
- **IAM**: Create and manage Lambda execution roles (`iam:CreateRole`, `iam:AttachRolePolicy`, `iam:PutRolePolicy`, `iam:PassRole`)
- **S3**: Configure bucket notifications (`s3:PutBucketNotification`, `s3:GetBucketNotification`)
- **CloudWatch**: Create log groups (`logs:CreateLogGroup`, `logs:PutRetentionPolicy`)

**Note**: All IAM roles created by this script will use the specified permission boundary ARN to ensure compliance with organizational policies.

### Prerequisites

Before setting up the server, several elements need to be deployed in the SS venue:
- A Route53 entry for a dual-stack ALB which points to the EC2 instance
- The S3 bucket for configuration files
- Proper security groups and networking configuration

## Installation

### Quick Start

1. SSH into your EC2 instance
2. Clone this repository
3. Navigate to the `terraform-ss-proxy` directory
4. **Configure parameters in install.sh** (see Configuration section below)
5. Run the installation script:

```bash
./install.sh
```

### Configuration Variables

**IMPORTANT**: Before running the installation, you must edit the configuration variables in `install.sh` to match your environment. The script uses the following default variables:

```bash
S3_BUCKET_NAME="ucs-shared-services-apache-config-dev-test"
PERMISSION_BOUNDARY_ARN="arn:aws:iam::237868187491:policy/mcp-tenantOperator-AMI-APIG"
AWS_REGION="us-west-2"
APACHE_HOST="www.dev.mdps.mcp.nasa.gov"
APACHE_PORT="4443"
RELOAD_DELAY="15"
OIDC_CLIENT_ID="ee3duo3i707h93vki01ivja8o"
COGNITO_USER_POOL_ID="us-west-2_yaOw3yj0z"
```

**Required Steps**:
1. Edit `install.sh` and update these variables for your environment
2. Ensure the values match your AWS infrastructure and requirements

Alternatively, you can override defaults by exporting environment variables before running the script:

```bash
export S3_BUCKET_NAME="my-custom-bucket"
export AWS_REGION="us-east-1"
./install.sh
```

### Amazon Cognito Configuration

**CRITICAL**: Before running the installation, you must configure your Amazon Cognito App Client with the correct callback URL.

1. **Navigate to your Cognito User Pool** in the AWS Console
2. **Go to App Clients** section
3. **Edit your App Client** (the one specified in `OIDC_CLIENT_ID`)
4. **Add the following to "Allowed callback URLs"**:
   ```
   https://{APACHE_HOST}:{APACHE_PORT}/unity/redirect-url
   ```
   
   For example, with the default values:
   ```
   https://www.dev.mdps.mcp.nasa.gov:4443/unity/redirect-url
   ```

5. **Save the changes**

**Note**: The callback URL must exactly match your `APACHE_HOST` and `APACHE_PORT` values, followed by `/unity/redirect-url`. If these don't match, authentication will fail.

### Install Options

The install script supports the following options:

```bash
# Full installation (Apache + Terraform)
./install.sh

# Terraform infrastructure only (requires existing Apache config)
./install.sh --terraform-only

# Destroy Terraform infrastructure (cleanup)
./install.sh --destroy-terraform
```

## Terraform Infrastructure

The installation script automatically sets up the required AWS infrastructure using Terraform:

### What Gets Created

1. **SQS FIFO Queue**: `apache-config-reload.fifo`
   - Used for debouncing multiple configuration changes
   - Content-based deduplication enabled
   - 14-day message retention

2. **Lambda Function**: `ss-proxy-config-reload-trigger`
   - Handles both S3 events and SQS message processing
   - Implements debouncing logic to prevent rapid successive reloads
   - Makes HTTPS calls to Apache reload endpoint

3. **IAM Role**: `unity-cs-proxy-reload-lambda-role`
   - Includes required permissions for SQS, CloudWatch Logs
   - Uses the specified permission boundary ARN

4. **S3 Bucket Notifications**
   - Triggers Lambda on `.conf` file changes
   - Monitors `ObjectCreated:*` and `ObjectRemoved:*` events

5. **CloudWatch Log Group**: `/aws/lambda/ss-proxy-config-reload-trigger`
   - Logs Lambda function execution and errors
   - 14-day retention for troubleshooting

6. **SQS Event Source Mapping**
   - Connects SQS queue to Lambda function
   - Batch size of 1 to maintain FIFO ordering

### Terraform State

The Terraform configuration uses a local backend and stores state in `terraform.tfstate` in the same directory.

### Manual Terraform Operations

If you need to run Terraform commands manually:

```bash
cd terraform-ss-proxy

# Initialize
terraform init

# Plan with custom variables
terraform plan \
  -var="s3_bucket_name=my-bucket" \
  -var="permission_boundary_arn=arn:aws:iam::123456789012:policy/MyBoundary"

# Apply
terraform apply

# Destroy (when needed)
terraform destroy
```

## Configuration Management

### File Upload Requirements

- Files uploaded to the S3 bucket **must have a `.conf` extension**
- Only `.conf` files will trigger configuration reloads
- Files are automatically synced to `/etc/apache2/venues.d/` on the server

### Reload Process

1. **S3 Event**: `.conf` file uploaded/modified/deleted
2. **Lambda Trigger**: S3 event triggers Lambda function
3. **SQS Queuing**: Lambda sends message to FIFO queue for debouncing
4. **Processing**: Lambda processes SQS message after debounce delay
5. **Apache Reload**: Lambda makes HTTPS call to reload Apache configuration

### Reload Throttling

The system implements intelligent throttling to ensure Apache configuration reloads are properly spaced while guaranteeing that every S3 event eventually triggers a reload.

#### How Throttling Works

1. **Time-Based Bucketing**: The system divides time into intervals (default: 15 seconds, configurable via `RELOAD_DELAY`)

2. **Boundary Calculation**: When an S3 event occurs, the Lambda calculates the next time boundary:
   ```
   Current time: 14:32:07
   Interval: 15 seconds  
   Next boundary: 14:32:15 (rounded up to next 15-second mark)
   ```

3. **SQS Message Queuing**: 
   - Message is sent to SQS FIFO queue immediately (no DelaySeconds)
   - `MessageDeduplicationId` = boundary timestamp for automatic deduplication
   - Multiple events targeting the same boundary are automatically deduplicated by SQS

4. **Lambda-Based Delay**: When the Lambda function receives an SQS message:
   - It calculates the remaining time until the target boundary
   - Waits (using setTimeout) until that exact boundary time
   - Then triggers the Apache reload

5. **Guaranteed Processing**: Each time window gets exactly one reload, but every S3 event is accounted for

#### Example Timeline

```
14:32:07 - S3 event → SQS message for boundary 14:32:15 (queued immediately)
14:32:10 - S3 event → REJECTED (duplicate for same boundary)
14:32:12 - S3 event → REJECTED (duplicate for same boundary)  
14:32:07 - Lambda receives message → waits 8 seconds → reload at 14:32:15
14:32:23 - S3 event → SQS message for boundary 14:32:30 (queued immediately)
14:32:23 - Lambda receives message → waits 7 seconds → reload at 14:32:30
```

#### FIFO Queue Compatibility

This approach is designed for **FIFO queue compatibility**:
- **No DelaySeconds**: FIFO queues don't support DelaySeconds > 0
- **Lambda-based timing**: Delay logic moved to Lambda function processing
- **Consistent timing**: AWS Lambda timing is reliable across instances
- **Order preservation**: FIFO guarantees maintain reload sequence

#### Configuration

- **`RELOAD_DELAY`**: Time interval in seconds (default: 15)
- **Lambda Timeout**: Should be set to at least 30 seconds to handle delays
- **SQS FIFO**: Uses content-based deduplication with 5-minute window

This approach ensures:
- ✅ No more than one reload per interval
- ✅ Every S3 event eventually triggers a reload  
- ✅ FIFO queue compatibility (no DelaySeconds restriction)
- ✅ Automatic deduplication of rapid changes
- ✅ Precise timing control within Lambda function

## Cleanup

### Destroying Infrastructure

To remove all AWS infrastructure created by this setup:

```bash
./install.sh --destroy-terraform
```

This will:

- Destroy the Lambda function and its execution role
- Remove the SQS FIFO queue
- Delete the CloudWatch log group
- Remove S3 bucket notifications
- Clean up all related AWS resources

**Note**: This does not affect the Apache installation or configuration files on the EC2 instance.

## Troubleshooting

### 403 Forbidden on /reload-config

If you get a 403 error when testing the reload endpoint, check:

1. **Token Configuration**: Verify the token was properly replaced in the Apache config:
   ```bash
   sudo grep "X-Reload-Token" /etc/apache2/sites-enabled/unity-cs-main.conf
   ```
   It should show your actual token, not `REPLACE_WITH_SECURE_TOKEN`.

2. **Test the endpoint manually**:
   ```bash
   # Get the token from the config
   TOKEN=$(sudo grep -oP "X-Reload-Token.*?'\K[^']+" /etc/apache2/sites-enabled/unity-cs-main.conf)
   
   # Test the endpoint
   curl -k -H "X-Reload-Token: $TOKEN" https://localhost:4443/reload-config
   ```

3. **Check Apache error logs**:
   ```bash
   sudo tail -f /var/log/apache2/error.log
   ```