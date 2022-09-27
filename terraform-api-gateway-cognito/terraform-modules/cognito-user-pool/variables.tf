variable "unity_uds_distribution_callback_urls" {
  type        = list
  description = "Unity UDS Distribution - List of Callback Urls"
  default     = ["https://<ADD REST API ID>.execute-api.us-west-2.amazonaws.com:9000/dev/"]
}

variable "uads_jupyter-development_client_callback_urls" {
  type        = list
  description = "Jupyterhub - List of Callback Urls"
  default     = ["http://localhost:8000/hub/oauth_callback"]
}

variable "uads_jupyter-development_client_logout_urls" {
  type        = list
  description = "Jupyterhub - List of Logout Urls"
  default     = ["http://localhost:8000/hub/oauth_callback/logout"]
}

variable "localhost_jupyterhub_callback_urls" {
  type        = list
  description = "Localhost Jupyterhub - List of Callback Urls"
  default     = ["http://localhost:8000/hub/oauth_callback"]
}

variable "localhost_jupyterhub_logout_urls" {
  type        = list
  description = "Localhost Jupyterhub - List of Logout Urls"
  default     = ["http://localhost:8000/hub/oauth_callback/logout"]
}

variable "hysds_ui_client_callback_urls" {
  type        = list
  description = "HySDS UI Client - List of Callback Urls"
  default     = ["https://<ADD REST API ID>.execute-api.us-west-2.amazonaws.com/dev/hysds-ui/"]
}

variable "hysds_ui_client_logout_urls" {
  type        = list
  description = "HySDS UI Client - List of Logout Urls"
  default     = ["https://<ADD REST API ID>.execute-api.us-west-2.amazonaws.com/dev/hysds-ui/logout"]
}

variable "localhost_hysds_ui_client_callback_urls" {
  type        = list
  description = "Local HySDS UI Client - List of Callback Urls"
  default     = ["http://localhost:8080"]
}

variable "localhost_hysds_ui_client_logout_urls" {
  type        = list
  description = "Local HySDS UI Client - List of Logout Urls"
  default     = ["http://localhost:8080/logout"]
}
