locals {

  monitor_api_endpoint = (
    var.sysdig_region == "onprem" ? var.secure_api_endpoint :
    var.sysdig_region == "us1" ? "https://secure.sysdig.com" :
    var.sysdig_region == "us2" ? "https://us2.app.sysdig.com" :
    var.sysdig_region == "us3" ? "https://app.us3.sysdig.com" :
    var.sysdig_region == "us4" ? "https://app.us4.sysdig.com" :
    var.sysdig_region == "eu1" ? "https://eu1.app.sysdig.com" :
    var.sysdig_region == "au1" ? "https://app.au1.sysdig.com" :
    "ERROR: Either 'sysdig_region' or 'secure_api_endpoint' variables must be defined"
  )

  secure_api_endpoint = (
    var.sysdig_region == "onprem" ? var.secure_api_endpoint :
    var.sysdig_region == "us1" ? "https://app.sysdigcloud.com" :
    var.sysdig_region == "us2" ? "https://us2.app.sysdig.com" :
    var.sysdig_region == "us3" ? "https://app.us3.sysdig.com" :
    var.sysdig_region == "us4" ? "https://app.us4.sysdig.com" :
    var.sysdig_region == "eu1" ? "https://eu1.app.sysdig.com" :
    var.sysdig_region == "au1" ? "https://app.au1.sysdig.com" :
    "ERROR: Either 'sysdig_region' or 'secure_api_endpoint' variables must be defined"
  )

  sysdig_collector_endpoint = (
    var.sysdig_region == "onprem" ? var.sysdig_collector_endpoint :
    var.sysdig_region == "us1" ? "collector.sysdigcloud.com" :
    var.sysdig_region == "us2" ? "ingest-us2.app.sysdig.com" :
    var.sysdig_region == "us3" ? "ingest.us3.sysdig.com" :
    var.sysdig_region == "us4" ? "ingest.us4.sysdig.com" :
    var.sysdig_region == "eu1" ? "ingest-eu1.app.sysdig.com" :
    var.sysdig_region == "au1" ? "ingest.au1.sysdig.com" :
    var.sysdig_collector_endpoint
  )

  secure_api_endpoint_check = regex("^https://", local.secure_api_endpoint)

  protoless_secure_api_endpoint = replace(local.secure_api_endpoint, "/^https:\\/\\//", "")
}
