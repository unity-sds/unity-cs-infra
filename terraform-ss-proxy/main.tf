terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
  
  # Local backend for state management
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "s3_bucket_name" {
  description = "Name of the S3 bucket to monitor for config changes"
  type        = string
}

variable "permission_boundary_arn" {
  description = "ARN of the permission boundary policy to apply to IAM roles"
  type        = string
}

variable "reload_token" {
  description = "Secure token for Apache reload authentication"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "apache_host" {
  description = "Apache host for reload endpoint"
  type        = string
  default     = "www.dev.mdps.mcp.nasa.gov"
}

variable "apache_port" {
  description = "Apache port for reload endpoint"
  type        = string
  default     = "4443"
}

variable "debounce_delay" {
  description = "Debounce delay in seconds"
  type        = number
  default     = 30
}

# SQS FIFO Queue for debouncing
resource "aws_sqs_queue" "apache_reload_queue" {
  name                       = "apache-config-reload.fifo"
  fifo_queue                = true
  content_based_deduplication = true
  
  # Visibility timeout should be longer than Lambda timeout
  visibility_timeout_seconds = 300
  
  # Message retention
  message_retention_seconds = 1209600  # 14 days
  
  tags = {
    Name        = "SS Proxy Config Reload Queue"
    Purpose     = "debounce-config-changes"
  }
}

# Lambda execution role
resource "aws_iam_role" "lambda_role" {
  name                 = "unity-cs-proxy-reload-lambda-role"
  permissions_boundary = var.permission_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "SS Proxy Reload Lambda Role"
  }
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "unity-cs-proxy-reload-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.apache_reload_queue.arn
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "apache_reload_trigger" {
  filename                       = "trigger_reload.zip"
  function_name                 = "ss-proxy-config-reload-trigger"
  role                         = aws_iam_role.lambda_role.arn
  handler                      = "trigger_reload.handler"
  runtime                      = "nodejs18.x"
  timeout                      = 60

  environment {
    variables = {
      APACHE_HOST      = var.apache_host
      APACHE_PORT      = var.apache_port
      RELOAD_TOKEN     = var.reload_token
      SQS_QUEUE_URL    = aws_sqs_queue.apache_reload_queue.url
      RELOAD_DELAY     = var.debounce_delay
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_cloudwatch_log_group.lambda_logs,
  ]

  tags = {
    Name        = "SS Proxy Config Reload Trigger"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/ss-proxy-config-reload-trigger"
  retention_in_days = 14

  tags = {
    Name        = "SS Proxy Reload Lambda Logs"
  }
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.apache_reload_trigger.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_suffix       = ".conf"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# Lambda permission for S3
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apache_reload_trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_bucket_name}"
}

# SQS event source mapping for Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.apache_reload_queue.arn
  function_name    = aws_lambda_function.apache_reload_trigger.arn
  batch_size       = 1
  enabled          = true
}

# Create the Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "trigger_reload.js"
  output_path = "trigger_reload.zip"
}

# Outputs
output "sqs_queue_url" {
  description = "URL of the SQS FIFO queue"
  value       = aws_sqs_queue.apache_reload_queue.url
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.apache_reload_trigger.function_name
}


output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.apache_reload_trigger.arn
}