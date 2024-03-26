# Sysdig Common Configuration

## Description

This module outputs the necessary configuration variables to configure the Sysdig tenant. Based on the `sysdig_region` we will get the correct monitor and secure endpoints.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Providers

No providers.

## Requirements

No requirements.
## Usage

Basic usage of this module is as follows:

```hcl
module "example" {
	 source  = "<module-path>"

	 # Required variables
	 sysdig_region  = 

	 # Optional variables
	 secure_api_endpoint  = ""
	 sysdig_collector_endpoint  = ""
	 sysdig_collector_port  = "6443"
}
```
## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_secure_api_endpoint"></a> [secure\_api\_endpoint](#input\_secure\_api\_endpoint) | Sysdig Secure API endpoint | `string` | `""` | no |
| <a name="input_sysdig_collector_endpoint"></a> [sysdig\_collector\_endpoint](#input\_sysdig\_collector\_endpoint) | Sysdig collector endpoint | `string` | `""` | no |
| <a name="input_sysdig_collector_port"></a> [sysdig\_collector\_port](#input\_sysdig\_collector\_port) | Sysdig collector port | `string` | `"6443"` | no |
| <a name="input_sysdig_region"></a> [sysdig\_region](#input\_sysdig\_region) | Sysdig region (if not on-prem).<br>Collector and API endpoints will be computed automatically from the region.<br>Must be one of 'us1' \| 'us2' \| 'us3' \| 'us4' \| 'eu1' \| 'au1'. | `string` | n/a | yes |

## Modules

No modules.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_monitor_api_endpoint"></a> [monitor\_api\_endpoint](#output\_monitor\_api\_endpoint) | Sysdig Monitor API endpoint |
| <a name="output_protoless_secure_api_endpoint"></a> [protoless\_secure\_api\_endpoint](#output\_protoless\_secure\_api\_endpoint) | Protocol-less Sysdig Secure API endpoint |
| <a name="output_secure_api_endpoint"></a> [secure\_api\_endpoint](#output\_secure\_api\_endpoint) | Sysdig Secure API endpoint |
| <a name="output_sysdig_collector_endpoint"></a> [sysdig\_collector\_endpoint](#output\_sysdig\_collector\_endpoint) | Sysdig collector endpoint |
| <a name="output_sysdig_collector_port"></a> [sysdig\_collector\_port](#output\_sysdig\_collector\_port) | Sysdig collector port |
| <a name="output_sysdig_onprem"></a> [sysdig\_onprem](#output\_sysdig\_onprem) | Sysdig On-Prem (false for SaaS) |
| <a name="output_sysdig_region"></a> [sysdig\_region](#output\_sysdig\_region) | Sysdig region (or 'onprem').<br>Collector and API endpoints will be computed automatically from the region.<br>Must be one of 'us1' \| 'us2' \| 'us3' \| 'us4' \| 'eu1' \| 'au1' \| 'onprem'. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
