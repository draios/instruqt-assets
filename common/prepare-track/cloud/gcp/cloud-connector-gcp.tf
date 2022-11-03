terraform {
  required_providers {
      sysdig = {
        source  = "sysdiglabs/sysdig"
      }
  }
}

variable "training_secure_api_token" {
  type        = string
  description = "The Sysdig API token"
}

variable "training_secure_url" {
  type        = string
  description = "The Sysdig Secure URL"
}

variable "training_gcp_region" {
  type        = string
  description = "The Sysdig Secure Region"
}

variable "training_gcp_project" {
  type        = string
  description = "The Sysdig Secure Region"
}

variable "gcp_creds" {
  type        = string
  description = "Auth credentials for the GCP SA from Instruqt"
}

provider "sysdig" {
  sysdig_secure_url       = var.training_secure_url
  sysdig_secure_api_token = var.training_secure_api_token
}

provider "google" {
  project = var.training_gcp_project
  region = var.training_gcp_region
  credentials = var.gcp_creds
}

provider "google-beta" {
  project = var.training_gcp_project
  region = var.training_gcp_region
  credentials = var.gcp_creds
}

module "secure-for-cloud_example_single-project" {
  source = "sysdiglabs/secure-for-cloud/google//examples/single-project"
  
  deploy_scanning = true
}