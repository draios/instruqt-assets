resource "kubernetes_secret" "example" {
  metadata {
    name      = "sko-2025-docker-secret-${var.group_id}"
    namespace = var.group_id
  }

  data = {
    ".dockerconfigjson" = "${file("${path.module}/docker/config.json")}"
  }

  type = "kubernetes.io/dockerconfigjson"
}