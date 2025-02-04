package sysdig

import future.keywords.in

allowed_runtimes := {"python3.9", "python3.10"}

default risky := false

risky = true {
input.Runtime in allowed_runtimes
}