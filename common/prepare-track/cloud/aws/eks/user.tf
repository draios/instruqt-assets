resource "aws_iam_user" "kraken" {
  name = local.name

  tags = local.tags
}

resource "aws_iam_access_key" "kraken" {
  user = aws_iam_user.kraken.name
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_iam_user_login_profile" "kraken" {
  user    = aws_iam_user.kraken.name
  password_length = 16
  password_reset_required  = true
}

resource "aws_iam_user_policy" "kraken" {
  name   = local.name
  user   = aws_iam_user.kraken.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*",
        ]
        Effect   = "Allow"
        Resource = module.eks.cluster_arn
      },
    ]
  })
}
