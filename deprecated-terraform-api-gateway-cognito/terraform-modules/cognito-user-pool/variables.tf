variable "user_pool_name" {
  type        = string
  description = "Name of the Cognito User Pool"
  default     = "/unity/cs/security/shared-services-cognito-user-pool/user-pool-id"
}

variable "customized_email_subject" {
  type        = string
  description = "Customized email subject to send the temporary password to users"
  default     = "Your temporary password for Unity Shared Services Cognito user pool"
}

variable "ssm_param_shared_services_cognito_user_pool_id" {
  type        = string
  description = "SSM Param for Shared Services Cognito User Pool ID"
  default     = "/unity/cs/security/shared-services-cognito-user-pool/user-pool-id"
}

variable "unity_uds_distribution_callback_urls" {
  type        = list(string)
  description = "Unity UDS Distribution - List of Callback Urls"
  default     = ["https://unity-shared-services-api-gatway-id.execute-api.us-west-2.amazonaws.com:9000/dev/"]
}

variable "uads_jupyter-development_client_callback_urls" {
  type        = list(string)
  description = "Jupyterhub - List of Callback Urls"
  default     = ["http://localhost:8000/hub/oauth_callback"]
}

variable "uads_jupyter-development_client_logout_urls" {
  type        = list(string)
  description = "Jupyterhub - List of Logout Urls"
  default     = ["http://localhost:8000/hub/oauth_callback/logout"]
}

variable "localhost_jupyterhub_callback_urls" {
  type        = list(string)
  description = "Localhost Jupyterhub - List of Callback Urls"
  default     = ["http://localhost:8000/hub/oauth_callback"]
}

variable "localhost_jupyterhub_logout_urls" {
  type        = list(string)
  description = "Localhost Jupyterhub - List of Logout Urls"
  default     = ["http://localhost:8000/hub/oauth_callback/logout"]
}

variable "hysds_ui_client_callback_urls" {
  type        = list(string)
  description = "HySDS UI Client - List of Callback Urls"
  default     = ["https://unity-shared-services-api-gatway-id.execute-api.us-west-2.amazonaws.com/dev/hysds-ui/"]
}

variable "hysds_ui_client_logout_urls" {
  type        = list(string)
  description = "HySDS UI Client - List of Logout Urls"
  default     = ["https://unity-shared-services-api-gatway-id.execute-api.us-west-2.amazonaws.com/dev/hysds-ui/logout"]
}

variable "localhost_hysds_ui_client_callback_urls" {
  type        = list(string)
  description = "Local HySDS UI Client - List of Callback Urls"
  default     = ["http://localhost:8080"]
}

variable "localhost_hysds_ui_client_logout_urls" {
  type        = list(string)
  description = "Local HySDS UI Client - List of Logout Urls"
  default     = ["http://localhost:8080/logout"]
}

variable "unity_cognito_user_groups" {
  description = "List of Unity Cognito User Groups"
  type = list(object({
    name          = string
    description   = string
  }))
  default = [
    {
      name = "Unity_Admin"
      description = "Unity_Admin Cognito User Group"
    },
    {
      name = "Unity_Viewer"
      description = "Unity_Viewer Cognito User Group"
    }
  ]
}
