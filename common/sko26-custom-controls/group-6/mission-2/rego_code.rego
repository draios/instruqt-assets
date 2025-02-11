################
#### REGO 1 ####
################
default risky := false

risky {
    input.type == "loadbalancer"
}

################
#### REGO 2 ####
################
default risky := false

risky {
    lower(input.serviceType) == "loadbalancer"
}

################
#### REGO 3 ####
################
default risky := false

risky {
    lower(input.serviceType) == "loadbalancer"
}

################
#### REGO 4 ####
################
default risky := false

risky {
    lower(input.type) == "load balancer"
}


################
#### REGO 5 ####
################
default risky := false

risky {
    false
    lower(input.type) == "loadbalancer"
}

################
#### REGO 6 ####
################

default risky := false

risky {
    lower(input.type) == "loadbalancer"
}

################
#### REGO 7 ####
################
default risky := false

risky {
    lower(input.kind) == "loadbalancer"
}

################
#### REGO 8 ####
################
default risky := false

risky or {
    lower(input.type) == "loadbalancer"
}

################
#### REGO 9 ####
################
default risky := false

risky {
    lower(input.type) == "service"
}

#################
#### REGO 10 ####
#################
default risky := false

risky {
    true == false
    lower(input.type) == "loadbalancer"
}