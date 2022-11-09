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

variable "deploy_scanner" {
  type        = bool
  description = "If true, deploys the Sysdig Scanner for ECR and Fargate"
}

provider "sysdig" {
  sysdig_secure_url       = var.training_secure_url
  sysdig_secure_api_token = var.training_secure_api_token
}

provider "aws" {
  region = var.training_aws_region
}

module "secure-for-cloud_example_single-account" {
  source = "sysdiglabs/secure-for-cloud/aws//examples/single-account"

  deploy_image_scanning_ecs = var.deploy_scanner
  deploy_image_scanning_ecr = var.deploy_scanner
  deploy_beta_image_scanning_ecr = var.deploy_scanner
}