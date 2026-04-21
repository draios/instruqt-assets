#------ root/outputs

output "ec2-public-ip" {
  value = module.compute.public_ip
}

output "ec2-id" {
  value = module.compute.instance_id
}

output "ec2-attacker-public-ip" {
  value = module.compute-attacker.public_ip
}

output "ec2-attacker-id" {
  value = module.compute-attacker.instance_id
}
