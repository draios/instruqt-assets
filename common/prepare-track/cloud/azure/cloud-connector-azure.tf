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

variable "training_azure_subscription" {
  type        = string
  description = "Azure Subscription ID"
}

provider "sysdig" {
  sysdig_secure_url       = var.training_secure_url
  sysdig_secure_api_token = var.training_secure_api_token
}

provider "azurerm" {
  features { }
  subscription_id = var.training_azure_subscription
}

module "secure_for_cloud_example_single_subscription" {
  source = "sysdiglabs/secure-for-cloud/azurerm//examples/single-subscription"

  deploy_scanning = false

  deploy_active_directory=false
} 