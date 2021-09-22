resource "sysdig_secure_notification_channel" "emailResource" {
  name                 = "DEMO_USE_CASE_E-mail_notification_channel_(from_Terraform)"
  enabled              = "true"
  type                 = "EMAIL"
  recipients           = "example@example.com"
  notify_when_ok       = "false"
  notify_when_resolved = "false"
}

resource "sysdig_secure_rule_container" "ruleResource" {
  name        = "DEMO_USE_CASE_Example_of_Container_Rule_(from_Terraform)"
  description = "This rule is just for training porpouses"
  tags        = ["container", "cis"]
  matching    = "true"
  containers  = ["foo", "foo:bar"]
}

resource "sysdig_secure_policy" "sample" {
  name        = "DEMO_USE_CASE_Example_of_Policy_(from_Terraform)"
  description = "This policy is just for training porpouses"
  enabled     = "true"
  severity    = 4
  scope       = "container.id != \"\""
  rule_names  = [sysdig_secure_rule_container.ruleResource.name]
  actions {
    container = "stop"
    capture {
      seconds_before_event = 5
      seconds_after_event  = 10
    }
  }
  notification_channels = [sysdig_secure_notification_channel.emailResource.id]
}