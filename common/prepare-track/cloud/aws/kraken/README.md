# Kraken Hunter Wowkrshop Workspace

## Description

In this workspace, we call and configure the necessary modules to create EKS clusters for the Kraken Hunter Wowkrshop.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.25.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.11.0 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.25.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.11.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.23.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0.5 |

## Usage

The basic usage of this module is as follows:

```hcl
module "example" {
	 source  = "<module-path>"

	 # Required variables
	 aws_account_id  = 
	 aws_region  = 
	 cluster_name  = 
	 eks_extra_admins  = 
	 rapid_response_passphrase  = 
	 secure_api_token  = 
	 secure_for_cloud_aws_region  = 
	 sysdig_access_key  = 
	 sysdig_monitor_api_token  = 
	 sysdig_region  = 

	 # Optional variables
	 cidr_block  = "10.0.0.0/16"
	 enviroment  = "staging"
	 k8s_version  = "1.29"
	 tags  = {
  "Environment": "staging",
  "ManagedBy": "Terraform",
  "Project": "infra-eks"
}
}
```

## Resources

| Name | Type |
|------|------|
| [helm_release.example_voting_app](https://registry.terraform.io/providers/hashicorp/helm/2.11.0/docs/resources/release) | resource |
| [helm_release.sysdig_deploy](https://registry.terraform.io/providers/hashicorp/helm/2.11.0/docs/resources/release) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpcs.kraken_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpcs) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID for deployment of the resources | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Region of the AWS account | `string` | n/a | yes |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | n/a | `string` | n/a | yes |
| <a name="input_eks_extra_admins"></a> [eks\_extra\_admins](#input\_eks\_extra\_admins) | A list of dictionaries where we specify the AWS arns and their groups to have access to the EKS cluster | <pre>list(object({<br>    arn      = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_enviroment"></a> [enviroment](#input\_enviroment) | Env logical environment i.e staging, sandbox, production | `string` | `"staging"` | no |
| <a name="input_k8s_version"></a> [k8s\_version](#input\_k8s\_version) | Kubernetes version | `string` | `"1.29"` | no |
| <a name="input_rapid_response_passphrase"></a> [rapid\_response\_passphrase](#input\_rapid\_response\_passphrase) | Specifies a passphrase to encrypt the traffic between the user and the host. | `string` | n/a | yes |
| <a name="input_secure_api_token"></a> [secure\_api\_token](#input\_secure\_api\_token) | Sysdig Secure API Token | `string` | n/a | yes |
| <a name="input_secure_for_cloud_aws_region"></a> [secure\_for\_cloud\_aws\_region](#input\_secure\_for\_cloud\_aws\_region) | AWS Region for deployment of Secure for Cloud components | `string` | n/a | yes |
| <a name="input_sysdig_access_key"></a> [sysdig\_access\_key](#input\_sysdig\_access\_key) | Sysdig agent access key | `string` | n/a | yes |
| <a name="input_sysdig_monitor_api_token"></a> [sysdig\_monitor\_api\_token](#input\_sysdig\_monitor\_api\_token) | Sysdig Monitor API Token | `string` | n/a | yes |
| <a name="input_sysdig_region"></a> [sysdig\_region](#input\_sysdig\_region) | 'us1' \| 'us2' \| 'us3' \| 'us4' \| 'eu1' \| 'au1' | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to the AWS resources | `map(string)` | <pre>{<br>  "Environment": "staging",<br>  "ManagedBy": "Terraform",<br>  "Project": "infra-eks"<br>}</pre> | no |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_common"></a> [common](#module\_common) | ../../../../../../modules/sysdig/common | n/a |
| <a name="module_infra-cluster-eks"></a> [infra-cluster-eks](#module\_infra-cluster-eks) | ../../../../../../modules/aws/infra/eks-test | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.1 |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cnames"></a> [eks\_cnames](#output\_eks\_cnames) | EKS Cluster names |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
