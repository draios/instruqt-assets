locals {
  cluster_name                  = var.cluster_name
  sysdig_region                 = var.sysdig_region
  sysdig_access_key             = var.sysdig_access_key
  secure_api_token              = var.secure_api_token
  sysdig_collector_endpoint     = module.common.sysdig_collector_endpoint
  sysdig_secure_url             = module.common.secure_api_endpoint
  sysdig_monitor_url            = module.common.monitor_api_endpoint
  protoless_secure_api_endpoint = module.common.protoless_secure_api_endpoint
  rapid_response_passphrase     = var.rapid_response_passphrase
}

module "common" {
  source        = "../../sysdig/common"
  sysdig_region = var.sysdig_region
}

resource "helm_release" "sysdig_deploy" {
  name             = "sysdig-deploy"
  repository       = "https://charts.sysdig.com"
  chart            = "sysdig-deploy"
  version          = "1.34.1"
  namespace        = "sysdig-agent"
  create_namespace = true
  wait             = false
  recreate_pods    = true
  timeout          = 600

  values = [
    file("${path.module}/sysdig-deploy-values.yaml")
    # file("${path.module}/dragent.yaml")
  ]

  set {
    name  = "global.sysdig.region"
    value = local.sysdig_region
  }

  set {
    name  = "global.clusterConfig.name"
    value = local.cluster_name
  }

  set_sensitive {
    name  = "global.sysdig.accessKey"
    value = local.sysdig_access_key
  }

  set_sensitive {
    name  = "admissionController.sysdig.secureAPIToken"
    value = local.secure_api_token
  }

  set {
    name  = "admissionController.clusterName"
    value = local.cluster_name
    type  = "string"
  }

  set {
    name  = "admissionController.sysdig.apiEndpoint"
    value = local.protoless_secure_api_endpoint
    type  = "string"
  }

  set {
    name  = "global.settings.tags"
    value = "role:${local.cluster_name}"
  }

  set {
    name  = "agent.collectorSettings.collectorHost"
    value = local.sysdig_collector_endpoint
  }

  set {
    name  = "nodeAnalyzer.nodeAnalyzer.apiEndpoint"
    value = local.protoless_secure_api_endpoint
  }

  set {
    name  = "kspmCollector.apiEndpoint"
    value = local.protoless_secure_api_endpoint
  }

  set {
    name  = "rapidResponse.rapidResponse.passphrase"
    value = local.rapid_response_passphrase
  }

  depends_on = [ time_sleep.wait_30_seconds ]

}

resource "time_sleep" "wait_30_seconds" {

  depends_on = [ module.infra-cluster-eks ]

  create_duration = "30s"
}
