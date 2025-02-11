variable "group_id" {
  type        = string
  description = "value of the group id, used to create different resources for each group and different k8s namespaces"
}

variable "region" {
  type        = string
  description = "value of the region"
  default     = "us-east-1"
}