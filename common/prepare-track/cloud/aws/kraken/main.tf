data "aws_vpcs" "kraken_vpc" {
  tags = {
    Name = "kraken"
  }
}

locals {
  name       = "kraken"
  tags = {
    Environment = var.enviroment
    ManagedBy   = "Terraform"
    Project     = "infra-eks"
    Name        = local.name
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.kraken_vpc.ids[0]]
  }

  tags = {
    Type = "private"
  }
}

module "infra-cluster-eks" {
  source            = "../eks"
  name              = var.cluster_name
  additional_admins = []
  k8s_version       = var.k8s_version
  vpc_id            = data.aws_vpcs.kraken_vpc.ids[0]
  subnets           = data.aws_subnets.private.ids 
  node_count        = 1
  enviroment        = var.enviroment
  instance_type     = "t2.medium"
}
