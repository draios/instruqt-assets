#---- modules/iam/outputs.tf
output "s3_profile" {
  value = aws_iam_instance_profile.s3_profile.name
}
