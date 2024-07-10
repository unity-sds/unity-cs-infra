variable "tags" {
  type    = map(string)
  default = {}
}

variable "deployment_name" {
  type    = string
  default = "unity-eks"
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
    metadata_options           = optional(map(any))
    block_device_mappings      = optional(map(object({
      device_name = string
      ebs = object({
        volume_size           = number
        volume_type           = string
        encrypted             = bool
        delete_on_termination = bool
      })
    })))
  }))

  default = {
    defaultGroup = {
      instance_types = ["m5.xlarge"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1
    }
  }
}

variable "aws_auth_roles" {
  description = "AWS auth roles to associate with the cluster"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "project" {
  description = "The unity project its installed into"
  type        = string
  default     = "UnknownProject"
}

variable "venue" {
  description = "The unity venue its installed into"
  type        = string
  default     = "UnknownVenue"
}

variable "installprefix" {
  description = "The management console install prefix"
  type        = string
  default     = "UnknownPrefix"
}
