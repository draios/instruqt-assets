locals {
  # List of the eks-admin role that will have access to everything in the k8s cluster
  eks_admin_role_def = [
    {
      rolearn  = aws_iam_role.kube_admin.arn
      username = "eks-admin"
      groups = [
        "system:masters"
      ]
    }
  ]
  # This is the list of dev roles that could later caonfigured with k8s RBAC based on the username
  eks_dev_roles = length(var.eks_dev_roles_map) != 0 ? [
    for map_role in var.eks_dev_roles_map : {
      rolearn  = lookup(map_role, "rolearn", "")
      username = lookup(map_role, "username", "")
      groups   = lookup(map_role, "groups", [])
    }
  ] : []

  aws_auth_admin_users = [
    for admin_users in var.additional_admins : {
      userarn  = lookup(admin_users, "arn", "")
      username = lookup(admin_users, "username", "")
      groups   = lookup(admin_users, "groups", [])
    }
  ]
}

resource "aws_iam_role" "kube_admin" {
  name        = "eks-admin-${local.name}"
  description = "Amazon EKS - Cluster role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          "AWS" : aws_iam_user.kraken.arn
        }
      },
    ]
  })

  inline_policy {
    name = "AmazonEKSAdminPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["eks:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

  tags = local.tags
}

resource "aws_iam_policy" "user_assume_kube_admin_role" {
  name        = "EKSAssumeEKSAdminPolicy-${local.name}"
  path        = "/"
  description = "User policy to assume the eks-admin-${local.name} IAM role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "sts:AssumeRole"
        ],
        Resource : aws_iam_role.kube_admin.arn
      }
    ]
  })

  tags = local.tags
}
