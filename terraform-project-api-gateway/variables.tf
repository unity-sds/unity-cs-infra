variable "region" {
  type        = string
  description = "Region"
  default     = "us-west-2"
}

variable "project_name" {
  type        = string
  description = "Project Name"
  default     = "TestProject"
}

variable "rest_api_name" {
  type        = string
  description = "REST API Name"
  default     = "Unity-${var.project_name} REST API Gateway"
}

variable "rest_api_description" {
  type        = string
  description = "REST API Description"
  default     = "Unity-${var.project_name} REST API Gateway"
}

variable "rest_api_stage" {
  type        = string
  description = "REST API Stage"
  default     = "dev"
}

variable "counter" {
  description = "value"
  type        = number
  default     = 1
}