#######################
######## AWS ##########
#######################
resource "sysdig_secure_posture_control" "lambda_approved_runtimes" {
  name                = "Custom - Lambda - Lambda runtime in list of approved runtimes - ${var.group_id}"
  description         = "Custom - Lambda - Lambda runtime in list of approved runtimes"
  resource_kind       = "AWS_LAMBDA_FUNCTION"
  severity            = "High"
  rego                = <<-EOF
            package sysdig

            import future.keywords.in

            allowed_runtimes := {"python3.9", "python3.10"}

            default risky := false

            risky = true {
            input.Runtime in allowed_runtimes
            }
        EOF
  remediation_details = <<-EOF
          **Using AWS CLI**\n 1. This Follow the steps bellow
        EOF
}

resource "sysdig_secure_posture_control" "sqs_queue_delay_seconds" {
  name                = "Custom - SQS - SQS queue delay seconds should not be above zero - ${var.group_id}"
  description         = "Custom - SQS - SQS queue delay seconds should not be above zero"
  resource_kind       = "AWS_SQS_QUEUE"
  severity            = "High"
  rego                = <<-EOF
        package sysdig

        default risky := false

        risky = true {
            to_number(input.DelaySeconds) > 0
        }
        EOF
  remediation_details = <<-EOF
          **Using AWS CLI**\n 1. This Follow the steps bellow
        EOF
}

resource "sysdig_secure_posture_control" "security_group_open_to_world_ssh" {
  name                = "Custom - SecurityGroup - Verify if SG has SSH TCP open to 0.0.0.0/0 - ${var.group_id}"
  description         = "Custom - SecurityGroup - Verify if SG has SSH TCP open to 0.0.0.0/0"
  resource_kind       = "AWS_SECURITY_GROUP"
  severity            = "High"
  rego                = <<-EOF
        package sysdig

        default risky := false

        risky = true {
            some i, j
            input.IpPermissions[i].FromPort == 22
            input.IpPermissions[i].ToPort == 22
            input.IpPermissions[i].IpProtocol == "tcp"
            input.IpPermissions[i].IpRanges[j].CidrIp == "0.0.0.0/0"
        }
        EOF
  remediation_details = <<-EOF
          **Using AWS CLI**\n 1. This Follow the steps bellow
        EOF
}

resource "sysdig_secure_posture_control" "internet_facing_application_load_balancer" {
  name                = "Custom - LoadBalancer - Check for presence of internet facing load balancer - ${var.group_id}"
  description         = "Custom - LoadBalancer - Check for presence of internet facing load balancer"
  resource_kind       = "AWS_ELBV2_LOAD_BALANCER"
  severity            = "High"
  rego                = <<-EOF
        package sysdig

        default risky := false

        risky = true {
            input.Scheme == "internet-facing"
        }
        EOF
  remediation_details = <<-EOF
          **Using AWS CLI**\n 1. This Follow the steps bellow
        EOF
}
#######################
######## K8S ##########
#######################
resource "sysdig_secure_posture_control" "kubernetes_service_type_loadbalancer" {
  name                = "Custom - Kubernetes Service - Check if service type is load balancer - ${var.group_id}"
  description         = "Custom - Kubernetes Service - Check if service type is load balancer"
  resource_kind       = "SERVICE"
  severity            = "High"
  rego                = <<-EOF
        package sysdig

        default risky := false

        risky {
            lower(input.type) == "loadbalancer"
        }
        EOF
  remediation_details = <<-EOF
          **Using AWS CLI**\n 1. This Follow the steps bellow
        EOF
}

resource "sysdig_secure_posture_control" "kubernetes_deployment_with_single_replica" {
  name                = "Custom - Kubernetes Deployment - Check if deployment has a single replica - ${var.group_id}"
  description         = "Custom - Kubernetes Deployment - Check if deployment has a single replica"
  resource_kind       = "DEPLOYMENT"
  severity            = "High"
  rego                = <<-EOF
        package sysdig

        import future.keywords.if

        default risky := false

        risky if {
            input.spec.replicas == 1
        }
        EOF
  remediation_details = <<-EOF
          **Using AWS CLI**\n 1. This Follow the steps bellow
        EOF
}

resource "sysdig_secure_posture_control" "kubernetes_secret_is_docker_cfg" {
  name                = "Custom - Kubernetes Secret - Secret type is dockerconfig or dockerconfigjson - ${var.group_id}"
  description         = "Custom - Kubernetes Secret - Secret type is dockerconfig or dockerconfigjson"
  resource_kind       = "SECRET"
  severity            = "High"
  rego                = <<-EOF
        package sysdig

        import future.keywords.in
        import future.keywords.if

        default risky := false

        risky if {
            lower(input.type) in {"kubernetes.io/dockercfg", "kubernetes.io/dockerconfigjson"}
        }
        EOF
  remediation_details = <<-EOF
          **Using AWS CLI**\n 1. This Follow the steps bellow
        EOF
}

resource "sysdig_secure_posture_control" "kubernetes_namespace_contain_argocd_hook_set_presync" {
  name                = "Custom - Kubernetes Namespace - Namespace is configured to use ArgoCD Hook with PreSync mode - ${var.group_id}"
  description         = "Custom - Kubernetes Namespace - Namespace is configured to use ArgoCD Hook with PreSync mode"
  resource_kind       = "NAMESPACE"
  severity            = "High"
  rego                = <<-EOF
        package sysdig

        import future.keywords.in
        import future.keywords.if

        default risky := false

        risky if {
            input.metadata.annotations["argocd.argoproj.io/hook"] == "PreSync"
        }
        EOF
  remediation_details = <<-EOF
          **Using AWS CLI**\n 1. This Follow the steps bellow
        EOF
}