terraform {
  required_providers {
      sysdig = {
        source  = "sysdiglabs/sysdig"
        version = "~>1.52.0"
      }
  }
}

variable "training_secure_api_token" {
  type        = string
  description = "The Sysdig API token"
  sensitive   = true
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
  sensitive   = true
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

module "sysdig-cloud-connector" {
  source                      = "git::https://github.com/sysdiglabs/demoenv-scenarios//terraform/modules/sysdig/cloud-connector-gcp?ref=v1.2.11"
  providers = {
    google-beta = google-beta
    sysdig      = sysdig
    google      = google
  }
  secure_for_cloud_gcp_project = var.training_gcp_project
}
