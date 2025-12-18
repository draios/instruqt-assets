#---- modules/iam/main.tf


resource "aws_iam_role" "s3_role" {
  name               = var.role_name
  assume_role_policy = var.assume_role_policy
}

resource "aws_iam_policy" "admin_policy_1" {
  name        = var.plc1_policy_name
  path        = var.plc1_path
  description = var.plc1_iam_policy_description
  policy      = var.plc1_iam_policy
}

resource "aws_iam_policy" "admin_policy_2" {
  name        = var.plc2_policy_name
  path        = var.plc2_path
  description = var.plc2_iam_policy_description
  policy      = var.plc2_iam_policy
}

resource "aws_iam_policy" "admin_policy_3" {
  name        = var.plc3_policy_name
  path        = var.plc3_path
  description = var.plc3_iam_policy_description
  policy      = var.plc3_iam_policy
}



resource "aws_iam_role_policy_attachment" "attachment_policy_1" {
  role       = aws_iam_role.s3_role.name
  policy_arn = aws_iam_policy.admin_policy_1.arn
}

resource "aws_iam_role_policy_attachment" "attachment_policy_2" {
  role       = aws_iam_role.s3_role.name
  policy_arn = aws_iam_policy.admin_policy_2.arn
}

resource "aws_iam_role_policy_attachment" "attachment_policy_3" {
  role       = aws_iam_role.s3_role.name
  policy_arn = aws_iam_policy.admin_policy_3.arn
}


resource "aws_iam_instance_profile" "s3_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.s3_role.name
}


resource "aws_iam_user" "admins" {
  count = var.total_admins
  name = "admin${count.index}"
}

# TODO attach policy to normal admins
# resource "aws_iam_user_policy_attachment" "vanilla_admin_attach" {

#   for_each = local.aws_iam_user.admins

#   user       = each.key
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }


resource "aws_iam_user" "user" {
  name = "Admin6"
}

resource "aws_iam_user_policy_attachment" "attach-user" {
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}