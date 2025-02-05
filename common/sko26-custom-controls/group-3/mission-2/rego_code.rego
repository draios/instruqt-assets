################
#### REGO 1 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.type) == "kubernetes.io/dockercfg" || "kubernetes.io/dockerconfigjson"
}

################
#### REGO 2 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.type) != "kubernetes.io/dockercfg"
}

################
#### REGO 3 ####
################
import future.keywords.in
import future.keywords.if

default risky := true

risky if {
    lower(input.type) in {"kubernetes.io/dockercfg", "kubernetes.io/dockerconfigjson"}
}

################
#### REGO 4 ####
################
default risky := false

risky {
    lower(input.serviceType) == "loadbalancer"
}

################
#### REGO 5 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.type) not in {"kubernetes.io/dockercfg", "kubernetes.io/dockerconfigjson"}
}

################
#### REGO 6 ####
################

import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.type) in {"kubernetes.io/dockercfg", "kubernetes.io/dockerconfigjson"}
}

################
#### REGO 7 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.type) in {"docker/cfg", "docker/json"}
}

################
#### REGO 8 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.type) == "kubernetes.io/dockercfg, kubernetes.io/dockerconfigjson"
}

################
#### REGO 9 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.kind) in {"kubernetes.io/dockercfg", "kubernetes.io/dockerconfigjson"}
}

#################
#### REGO 10 ####
#################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.type) == "kubernetes.io/dockercfg" and lower(input.type) == "kubernetes.io/dockerconfigjson"
}