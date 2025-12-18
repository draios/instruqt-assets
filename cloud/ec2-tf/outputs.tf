#------ root/outputs

output "ec2-public_ip" {
  value = module.compute.public_ip
}

output "ec2-id" {
  value = module.compute.instance_id
}

