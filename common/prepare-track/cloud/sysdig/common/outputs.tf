output "sysdig_region" {
  description = "Sysdig region (or 'onprem').\nCollector and API endpoints will be computed automatically from the region.\nMust be one of 'us1' | 'us2' | 'us3' | 'us4' | 'eu1' | 'au1' | 'onprem'."
  value       = var.sysdig_region
}

output "secure_api_endpoint" {
  description = "Sysdig Secure API endpoint"
  value       = local.secure_api_endpoint
}

output "monitor_api_endpoint" {
  description = "Sysdig Monitor API endpoint"
  value       = local.monitor_api_endpoint
}

output "protoless_secure_api_endpoint" {
  description = "Protocol-less Sysdig Secure API endpoint"
  value       = local.protoless_secure_api_endpoint
}

output "sysdig_collector_endpoint" {
  description = "Sysdig collector endpoint"
  value       = local.sysdig_collector_endpoint
}

output "sysdig_collector_port" {
  description = "Sysdig collector port"
  value       = var.sysdig_collector_port
}

output "sysdig_onprem" {
  description = "Sysdig On-Prem (false for SaaS)"
  value       = var.sysdig_region == "onprem"
}
