package sysdig

default risky := false

risky = true {
    to_number(input.DelaySeconds) > 0
}