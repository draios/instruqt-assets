variable "cluster_name" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "Region of the AWS account"
}

variable "enviroment" {
  description = "Env logical environment i.e staging, sandbox, production"
  type        = string
  default     = "staging"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to the AWS resources"
  default = {
    Environment = "staging"
    ManagedBy   = "Terraform"
    Project     = "infra-eks"
  }
}

variable "sysdig_access_key" {
  description = "Sysdig agent access key"
  type        = string
  sensitive   = true
}

variable "sysdig_region" {
  description = "'us1' | 'us2' | 'us3' | 'us4' | 'eu1' | 'au1'"
  type        = string
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The CIDR block for the VPC"
}

variable "secure_api_token" {
  description = "Sysdig Secure API Token"
  type        = string
  sensitive   = true
}

variable "rapid_response_passphrase" {
  description = "Specifies a passphrase to encrypt the traffic between the user and the host."
  type        = string
  sensitive   = true
}

variable "secure_for_cloud_aws_region" {
  type        = string
  description = "AWS Region for deployment of Secure for Cloud components"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID for deployment of the resources"
}
