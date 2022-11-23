terraform {
  required_providers {
    sysdig = {
      source = "sysdiglabs/sysdig"
      version = "0.5.39"
    }
  }
}

variable "sysdig_secure_api_token" {
  default = ""
}
variable "sysdig_monitor_api_token" {
  default = ""
}

provider "sysdig" {
  sysdig_secure_api_token = var.sysdig_secure_api_token
  sysdig_monitor_api_token = var.sysdig_monitor_api_token
}

#sysdig-secure-notification-channel
resource "sysdig_secure_notification_channel_email" "sample-email" {
  name                 = "Example Channel (from Terraform)"
  enabled              = true
  recipients           = ["myemail@sample.com"]
  notify_when_ok       = false
  notify_when_resolved = false
}

#sysdig-secure-rule
resource "sysdig_secure_rule_container" "sample" {
  name        = "Example Container Rule (from Terraform)"
  description = "This rule is just for training"
  tags        = ["container", "cis"]
  matching   = true // default
  containers = ["foo", "foo:bar"]
}

#sysdig-secure-policy
resource "sysdig_secure_policy" "sample" {
  name        = "Example Policy (from Terraform)"
  description = "This policy is just for training"
  enabled     = true
  severity    = 4
  scope       = "container.id != \"\""
  rule_names  = [sysdig_secure_rule_container.sample.name]

  actions {
    container = "stop"
    capture {
      seconds_before_event = 5
      seconds_after_event  = 10
    }
  }

  notification_channels = [sysdig_secure_notification_channel_email.sample-email.id]
}
