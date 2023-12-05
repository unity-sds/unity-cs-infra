variable "ssm_parameters" {
  description = "A list of SSM parameters to create"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = [
    {
      name  = "parameter1"
      type  = "String"
      value = "value1"
    },
    {
      name  = "parameter2"
      type  = "String"
      value = "value2"
    },
  ]
}

variable "venue" {
  description = "The target venue"
  type        = string
}

variable "project" {
  description = "The target project"
  type        = string
}

variable "privatesubnets" {
  description = "The preferred private subnets"
  type        = string
}

variable "publicsubnets" {
  description = "The preferred public subnets"
  type        = string
}

variable "tags" {
  description = "AWS Tags"
  type = map(string)
}

variable "deployment_name" {
  description = "The deployment name"
  type        = string
}
