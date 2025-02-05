## Enter your Terraform code for your custom control

resource "sysdig_secure_posture_control" "kubernetes_namespace_contain_argocd_hook_set_presync" {
  name                = "Custom - Kubernetes Namespace - Namespace is configured to use ArgoCD Hook with PreSync mode - ${var.group_id}"
  description         = "Custom - Kubernetes Namespace - Namespace is configured to use ArgoCD Hook with PreSync mode"
  resource_kind       = "NAMESPACE"
  severity            = "High"
  rego                = # Enter the right REGO code to comply with your mandate
  remediation_details = <<-EOF
          **Patch your manifest with:**\n 1. This Follow the steps bellow
        EOF
}