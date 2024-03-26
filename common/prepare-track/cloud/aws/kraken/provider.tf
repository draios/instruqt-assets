terraform {
  backend "s3" {}

  #fix the version of terraform 
  required_version = "~>1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.0"
    }
  }

}

provider "helm" {

  # If we set this, when we install a chart we could face the following error `Error: Provider produced inconsistent final plan`
  # Check the following issues https://github.com/hashicorp/terraform-provider-helm/issues/711, https://github.com/hashicorp/terraform-provider-helm/issues/372#issuecomment-1170195095
  experiments {
    manifest = false # Enable storing of the rendered manifest for helm_release so the full diff of what is changing can been seen in the plan.
  }

  kubernetes {
    host                   = module.infra-cluster-eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.infra-cluster-eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.infra-cluster-eks.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = module.infra-cluster-eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.infra-cluster-eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.infra-cluster-eks.cluster_name]
    command     = "aws"
  }
}
