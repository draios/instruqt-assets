variable "sysdig_region" {
  description = "Sysdig region (if not on-prem).\nCollector and API endpoints will be computed automatically from the region.\nMust be one of 'us1' | 'us2' | 'us3' | 'us4' | 'eu1' | 'au1'."
  type        = string

  validation {
    condition     = contains(["us1", "us2", "us3", "us4", "eu1", "au1", "onprem"], var.sysdig_region)
    error_message = "Invalid region."
  }
}

variable "sysdig_collector_endpoint" {
  description = "Sysdig collector endpoint"
  type        = string
  default     = ""
}

variable "sysdig_collector_port" {
  description = "Sysdig collector port"
  type        = string
  default     = "6443"
}

variable "secure_api_endpoint" {
  description = "Sysdig Secure API endpoint"
  type        = string
  default     = ""
}
