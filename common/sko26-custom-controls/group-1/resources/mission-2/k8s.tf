resource "kubernetes_deployment" "example" {
  metadata {
    name      = "sko-2025-deployment-with-root-${var.group_id}"
    namespace = var.group_id
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "example"
      }
    }

    template {
      metadata {
        labels = {
          app = "example"
        }
      }

      spec {
        container {
          name  = "example-container"
          image = "nginx:latest"

          security_context {
            run_as_user = 0
          }
        }
      }
    }
  }
}