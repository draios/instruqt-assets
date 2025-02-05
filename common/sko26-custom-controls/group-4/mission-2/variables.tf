variable "group_id" {
  type        = string
  description = "value of the group id, used to create different resources for each group and different k8s namespaces"
}

variable "api_url" {
  description = "value of the api url"
  type        = string
}

variable "sysdig_token" {
  description = "value of the sysdig token"
  type        = string
  sensitive   = true
}