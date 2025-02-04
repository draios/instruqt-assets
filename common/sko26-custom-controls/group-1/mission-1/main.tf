terraform {
  required_providers {
    sysdig = {
      source = "sysdiglabs/sysdig"
    }
  }
}

provider "sysdig" {
  sysdig_secure_url       = var.api_url
  sysdig_secure_api_token = var.sysdig_token
}

## Enter your Terraform code for your custom control