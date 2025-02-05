################
#### REGO 1 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    input.annotations["argocd.argoproj.io/hook"] == "PreSync"
}

################
#### REGO 2 ####
################
import future.keywords.in
import future.keywords.if

default risky := true

risky if {
    input.metadata.annotations["argocd.argoproj.io/hook"] == "PreSync"
}

################
#### REGO 3 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    input.metadata.annotations["argocd.argoproj.io/hook"] in "PreSync"
}

################
#### REGO 4 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    input.metadata.labels["argocd.argoproj.io/hook"] == "PreSync"
}

################
#### REGO 5 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    lower(input.metadata.annotations["argocd.argoproj.io/hook"]) == "PreSync"
}

################
#### REGO 6 ####
################

import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    input.metadata.annotations["argocd.argoproj.io/hook"] == "PreSync"
}

################
#### REGO 7 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    not input.metadata.annotations["argocd.argoproj.io/hook"] == "PreSync"
}

################
#### REGO 8 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    input.metadata.annotations["argocd.argoproj.io/sync-wave"] == "PreSync"
}

################
#### REGO 9 ####
################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    false
    input.metadata.annotations["argocd.argoproj.io/hook"] == "PreSync"
}

#################
#### REGO 10 ####
#################
import future.keywords.in
import future.keywords.if

default risky := false

risky if {
    input.metadata.annotations["argocd.argoproj.io/hook"] == "Sync"
}