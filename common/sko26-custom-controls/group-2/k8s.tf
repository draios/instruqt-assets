resource "kubernetes_service" "example" {
  metadata {
    name      = "sko-2025-service-${var.group_id}"
    namespace = var.group_id
  }

  spec {
    selector = {
      app = "main"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}