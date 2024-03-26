output "eks_cname" {
  value       = module.infra-cluster-eks.cluster_name
  description = "EKS Cluster names"
}

output "user_access_key" {
  value       = module.infra-cluster-eks.user_access_key
  description = "The access key for the Kraken user"
}

output "user_secret_key" {
  value       = module.infra-cluster-eks.user_secret_key
  sensitive   = true
  description = "The secret key for the Kraken user"
}

output "user_password" {
  value       = module.infra-cluster-eks.user_password
  sensitive   = true
  description = "The password for the Kraken user"
}
