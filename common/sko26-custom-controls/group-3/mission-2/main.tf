## Enter your Terraform code for your custom control

resource "sysdig_secure_posture_control" "kubernetes_secret_is_docker_cfg" {
  name                = "Custom - SKO26 - Kubernetes Secret - Secret type is dockerconfig or dockerconfigjson - ${var.group_id}"
  description         = "Custom - SKO26 - Kubernetes Secret - Secret type is dockerconfig or dockerconfigjson"
  resource_kind       = "SECRET"
  severity            = "High"
  rego                = # Enter the right REGO code to comply with your mandate
  remediation_details = <<-EOF
          **Patch your manifest with:**\n 1. This Follow the steps bellow
        EOF
}