data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "tls_certificate" "cluster" {
  url = module.eks.cluster_oidc_issuer_url
}

locals {
  name            = var.name
  cluster_version = var.k8s_version
  instance_type   = var.instance_type
  region          = data.aws_region.current.name
  partition       = data.aws_partition.current.partition

  tags = {
    ClusterName = var.name
    Environment = var.enviroment
    ManagedBy   = "Terraform"
    Project     = "infra-eks"
  }
}

################################################################################
# EKS Module
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>20.0"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  # To add the IAM identity of the creator of the cluster to the Kubernetes RBAC configuration
  enable_cluster_creator_admin_permissions = true

    access_entries = {
    student_admin = {
      principal_arn = aws_iam_user.kraken.arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # EKS Addons
  cluster_addons = {
    aws-ebs-csi-driver = {
      addon_version = "v1.28.0-eksbuild.1"
    }
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      before_compute              = true
      addon_version               = "v1.16.2-eksbuild.1" # Ref to https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html#vpc-cni-latest-available-version
      configuration_values = jsonencode({
        enableNetworkPolicy = "true" # Adding support for K8s Network Policies
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnets

  eks_managed_node_groups = {
    default = {
      use_name_prefix = true

      #create_launch_template = false
      #launch_template_name   = "template"

      min_size     = var.node_count
      max_size     = var.node_count
      desired_size = var.node_count

      remote_access = var.ssh_public_key == null ? {} : {
        ec2_ssh_key = aws_key_pair.node_key_pair[0].id
      }

      instance_types = [local.instance_type]
    }
  }

  enable_irsa = true

  # cluster_identity_providers = var.eks_oidc_idp

  # Additional node security group rules to allow access from the control plane to the Sysdig Admission Controller webhook port
  node_security_group_additional_rules = {
    ingress_allow_access_from_control_plane_to_sysdig_ac = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 5000
      to_port                       = 5000
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of Sysdig Admission Controller"
    }
  }

  tags = local.tags
}


resource "aws_key_pair" "node_key_pair" {
  count           = var.ssh_public_key == null ? 0 : 1
  key_name_prefix = "eks-${var.name}"
  public_key      = file(var.ssh_public_key)
  tags            = local.tags
}
