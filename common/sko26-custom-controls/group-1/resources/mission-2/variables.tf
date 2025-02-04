variable "group_id" {
  type        = string
  description = "value of the group id, used to create different resources for each group and different k8s namespaces"
}

/* variable "region" {
  type        = string
  description = "value of the region"
  default     = "us-east-1"
}

variable "cluster_name" {
  type        = string
  description = "value of the cluster name"
  default     = "eks-sko-2025"
}

variable "cluster_endpoint" {
  type        = string
  description = "value of the cluster endpoint"
  default     = ""
}

variable "cluster_ca_certificate" {
  type        = string
  description = "value of the cluster ca certificate"
  default     = ""
}

variable "cluster_token" {
  type        = string
  description = "value of the cluster token"
  default     = ""
} */