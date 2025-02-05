locals {
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr               = "170.0.0.0/18"
}