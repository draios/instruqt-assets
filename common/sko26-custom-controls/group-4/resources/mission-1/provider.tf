provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Team = "${var.group_id}"
      SKO  = "2026"
    }
  }
}

### required providers section
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }
}