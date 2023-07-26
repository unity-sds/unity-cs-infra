variable "region" {
  type        = string
  description = "Region"
  default     = "us-west-2"
}

variable "shared_services_rest_api_name" {
  type        = string
  description = "Shared services REST API name"
  default     = "Unity Shared Services REST API Gateway"
}

variable "sample_rest_api_integration_uri" {
  type = string
  description = "Sample REST API Integration URI"
  default = "https://sample-rest-api-id.execute-api.us-west-2.amazonaws.com/dev/{proxy}"
}

variable "sample_website_integration_uri" {
  type = string
  description = "Sample Website Integration URI"
  default = "https://www.wikipedia.org"
}

variable "rest_api_stage" {
  type        = string
  description = "REST API Stage Name"
  default     = "dev"
}
