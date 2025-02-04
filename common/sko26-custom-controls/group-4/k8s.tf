resource "kubernetes_namespace" "example_namespace" {
  metadata {
    name = "example-namespace"
    annotations = {
      "argocd.argoproj.io/hook" = "PreSync"
    }
  }
}