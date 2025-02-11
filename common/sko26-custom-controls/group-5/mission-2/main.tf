## Enter your Terraform code for your custom control

resource "sysdig_secure_posture_control" "kubernetes_deployment_with_single_replica" {
  name                = "Custom - SKO26 - Kubernetes Deployment - Check if deployment has a single replica - ${var.group_id}"
  description         = "Custom - SKO26 - Kubernetes Deployment - Check if deployment has a single replica"
  resource_kind       = "DEPLOYMENT"
  severity            = "High"
  rego                = # Enter the right REGO code to comply with your mandate
  remediation_details = <<-EOF
          **Patch your resource with**\n 1. This Follow the steps bellow
        EOF
}