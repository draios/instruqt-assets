package sysdig

import future.keywords.if

default risky := false

risky if {
    input.Scheme == "internet-facing"
}