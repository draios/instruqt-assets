################
#### REGO 1 ####
################
import future.keywords.if

default risky := false

risky if {
    input.spec.replicas >= 1
}

################
#### REGO 2 ####
################
import future.keywords.if

default risky := false

risky if {
    input.spec.replicas != 1
}

################
#### REGO 3 ####
################
import future.keywords.if

default risky := false

risky if {
    input.spec.replica == 1
}

################
#### REGO 4 ####
################
import future.keywords.if

default risky := false

risky if {
    input.spec.replicas == "1"
}

################
#### REGO 5 ####
################
import future.keywords.if

default risky := false

risky if {
    false
    input.spec.replicas == 1
}

################
#### REGO 6 ####
################
import future.keywords.if

default risky := false

risky if {
    input.spec.replicas == 1
}

################
#### REGO 7 ####
################
import future.keywords.if

default risky := false

risky if {
    [input.spec.replicas == 1]
}

################
#### REGO 8 ####
################
import future.keywords.if

default risky := false

risky if {
    input.replicas == 1
}

################
#### REGO 9 ####
################
import future.keywords.if

default risky := false

risky or {
    input.spec.replicas == 1
}

#################
#### REGO 10 ####
#################
import future.keywords.if

default risky := false

risky if {
    true == false
    input.spec.replicas == 1
}