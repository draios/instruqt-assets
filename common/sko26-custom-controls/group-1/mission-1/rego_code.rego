package sysdig

default risky := false

risky = true {
    input.Scheme == "internet-facing"
}