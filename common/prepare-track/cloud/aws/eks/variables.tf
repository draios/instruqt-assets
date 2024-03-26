variable "name" {
  description = "EKS cluster name"
  type        = string
}

variable "node_count" {
  type        = number
  default     = 1
  description = "The minimun number of nodes to run in the cluster"
}

variable "instance_type" {
  type        = string
  default     = "t2.medium"
  description = "The type of the instance nodes"
}

variable "ssh_public_key" {
  description = "Path to the SSH Public key file"
  type        = string
  default     = null
}

variable "additional_admins" {
  description = "List of ARNs for users that should have admin permissions in the cluster"
  type = list(object({
    arn      = string
    username = string
    groups   = list(string)
  }))
}

variable "eks_dev_roles_map" {
  description = "This is a list map of the arn roles that tehir metadata that would be added in the aws-auth configmap for authenticaiton."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "enviroment" {
  type        = string
  description = "Env logical environment i.e staging, sandbox, production"
  default = "staging"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets (preferably private subnets)"
}

variable "vpc_id" {
  description = "The VPC ID where the EKS cluster will be created"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}
