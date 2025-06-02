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
}

variable "training_secure_url" {
  type        = string
  description = "The Sysdig Secure URL"
}

variable "training_azure_subscription" {
  type        = string
  description = "Azure Subscription ID"
}

variable "training_azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "training_azure_region" {
  type        = string
  description = "The Azure Region"
  default     = "westus2"
}

provider "sysdig" {
  sysdig_secure_url       = var.training_secure_url
  sysdig_secure_api_token = var.training_secure_api_token
}

provider "azurerm" {
  features {}
  subscription_id = var.training_azure_subscription
  tenant_id       = var.training_azure_tenant_id
}

provider "azuread" {
  tenant_id       = var.training_azure_tenant_id
}

resource "random_string" "random_suffix" {
  length  = 3
  special = false
  upper   = false
}


module "sysdig-cloud-connector" {
  source                                 = "git::https://github.com/sysdiglabs/demoenv-scenarios//terraform/modules/sysdig/sysdig/cloud-connector-azure?ref=v1.2.11"
  secure_for_cloud_azure_subscription_id = var.training_azure_subscription
  secure_for_cloud_azure_tenant_id       = var.training_azure_tenant_id
  azure_region                           = var.training_azure_region
}
