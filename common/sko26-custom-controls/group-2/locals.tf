locals {
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr               = "170.0.0.0/18"
  cluster_endpoint       = var.cluster_endpoint == "" ? data.aws_eks_cluster.this.endpoint : var.cluster_endpoint
  cluster_ca_certificate = var.cluster_ca_certificate == "" ? base64decode(data.aws_eks_cluster.this.certificate_authority[0].data) : var.cluster_ca_certificate
  cluster_token          = var.cluster_token == "" ? data.aws_eks_cluster_auth.this.token : var.cluster_token
}