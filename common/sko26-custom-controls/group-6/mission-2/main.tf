## Enter your Terraform code for your custom control

resource "sysdig_secure_posture_control" "kubernetes_service_type_loadbalancer" {
  name                = "Custom - SKO26 - Kubernetes Service - Check if service type is load balancer - ${var.group_id}"
  description         = "Custom - SKO26 - Kubernetes Service - Check if service type is load balancer"
  resource_kind       = "SERVICE"
  severity            = "High"
  rego                = # Enter the right REGO code to comply with your mandate
  remediation_details = <<-EOF
          **Patch your manifest with:**\n 1. This Follow the steps bellow
        EOF
}