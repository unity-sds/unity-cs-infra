variable "region" {
  type        = string
  description = "Region"
  default     = "us-west-2"
}

variable "rest_api_name" {
  type        = string
  description = "REST API Name"
  default     = "Unity Shared Services REST API Gateway"
}

variable "rest_api_description" {
  type        = string
  description = "REST API Description"
  default     = "Unity Shared Services REST API Gateway"
}

variable "venue" {
  type        = string
  description = "Venue for deployment"
  default     = "prod"
}

variable "rest_api_stage" {
  type        = string
  description = "REST API Stage Name"
  default     = "prod"
}
