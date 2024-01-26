variable "tags" {
  type = map(string)
  default = {}
}

variable "deployment_name" {
  type = string
  default = "unity-dev-ryan"
}

variable "nodegroups" {
  description = "The nodegroups configuration"

  type = map(object({
    create_iam_role            = optional(bool)
    iam_role_arn               = optional(string)
    ami_id                     = optional(string)
    min_size                   = optional(number)
    max_size                   = optional(number)
    desired_size               = optional(number)
    instance_types             = optional(list(string))
    capacity_type              = optional(string)
    enable_bootstrap_user_data = optional(bool)
  }))

  default = { 
    defaultGroup ={
      instance_types = ["m5.xlarge"]
      min_size = 1
      max_size = 1
      desired_size = 1
    }
  }
}

variable "cluster_version" {
  type    = string
  default = "1.27"
}