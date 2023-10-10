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

variable "training_aws_region" {
  type        = string
  description = "The AWS Region"
}

provider "sysdig" {
  sysdig_secure_url       = var.training_secure_url
  sysdig_secure_api_token = var.training_secure_api_token
}

provider "aws" {
  region = var.training_aws_region
}

module "sysdig-sfc-agentless" {
  source = "sysdiglabs/secure-for-cloud/aws//modules/services/cloud-bench"
}
