/* provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Team = "${var.group_id}"
      SKO  = "2025"
    }
  }
} */

provider "kubernetes" {
  config_path = "~/.kube/config"
}

### required providers section
terraform {
  required_providers {
/*     aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    } */
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.22"
    }
/*     kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    } */
  }
}