terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.21"
    }
  }

  backend "s3" { 
    bucket = "S3_NAME"
    key    = "infra-tfstate"
    region     = "us-east-1"
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "us-east-1"
}

module "compute" {
  source               = "./module/compute"
  ami                  = "ami-0408adfcef670a71e"
  instance_type        = "m4.xlarge"
  tag_name             = "ec2-EC2_NAME"
  sg                   = module.security.webserver_sg
  user_data            = file("./scripts/userdata.tpl")
  iam_instance_profile = module.iam.s3_profile
  public_key_path      = "~/.ssh/my_sshkey.pub"
}

module "security" {
  source = "./module/security"
}

module "iam" {
  source                 = "./module/iam"
  role_name              = "ec2-role-EC2_ROLE_NAME"
  instance_profile_name  = "ec2-instance-profile"
  assume_role_policy     = file("./policy/ec2-trusted-id.tpl")

  plc1_policy_name            = "users-and-keys"
  plc1_path                   = "/"
  plc1_iam_policy_description = "creating access keys, limited"
  plc1_iam_policy             = templatefile("./policy/plc-users-and-keys-policy.tpl", { AWS_ACCOUNT_ID = var.AWS_ACCOUNT_ID})

  plc2_policy_name            = "admin-read1"
  plc2_path                   = "/"
  plc2_iam_policy_description = "read1 access for admin users"
  plc2_iam_policy             = templatefile("./policy/plc-admin-read1-policy.tpl", { AWS_ACCOUNT_ID = var.AWS_ACCOUNT_ID})

  plc3_policy_name            = "admin-read2"
  plc3_path                   = "/"
  plc3_iam_policy_description = "read2 access for admin users"
  plc3_iam_policy             = templatefile("./policy/plc-admin-read2-policy.tpl", { AWS_ACCOUNT_ID = var.AWS_ACCOUNT_ID})

  # users
  total_admins  = 5
}

module "s3" {
  source        = "./module/s3"
  bucket_name   = "tf-state-"
  object_key    = "LUIT"
  object_source = "/dev/null"
}

# resource "aws_db_instance" "clients-db" {
#   allocated_storage    = 10
#   db_name              = "mydb"
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t3.micro"
#   username             = "foo"
#   password             = "foobarbaz"
#   skip_final_snapshot  = true
# }