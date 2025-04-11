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
  default     = "https://us2.app.sysdig.com"
}

variable "training_aws_region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-1"
}

provider "sysdig" {
  sysdig_secure_url       = var.training_secure_url
  sysdig_secure_api_token = var.training_secure_api_token
}

provider "aws" {
  region = var.training_aws_region
}

variable "scanning_account_id" {
  type        = string
  description = "The Sysdig AWS account ID that performs the scanning"
}

variable "enable_cloudtrail" {
  type        = bool
  description = "Enable CloudTrail setup"
  default     = true
}

module "sysdig-cloud-connector" {
  source                      = "git::https://github.com/sysdiglabs/demoenv-scenarios//terraform/modules/sysdig/cloud-connector-aws?ref=v1.2.11"
  secure_for_cloud_aws_region = var.training_aws_region
  scanning_account_id         = var.scanning_account_id
  enable_cloudtrail           = var.enable_cloudtrail
}
