variable "project_id" {
  description = "Your GCP project ID"
  type        = string
  default     = null
  sensitive   = true
}

variable "user" {
  description = "Your GHCR User"
  type = string
  default     = null
  sensitive   = true
}

variable "password" {
  description = "Your GHCR User Password"
  type = string
  default     = null
  sensitive   = true
  
}

variable "registry" {
  description = "Artifactory path to container location for the frontend"
  default = "https://ghcr.io"
  type = string
  
}

variable "secret_name" {
  description = "The name of the docker secret in the secret manager object"
  default = "ghcr-secret"
  type = string
}

variable "region" {
  default     = "europe-west1"
  description = "GCP region to deploy to"
}
