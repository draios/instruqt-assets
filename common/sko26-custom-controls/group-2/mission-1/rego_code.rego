package sysdig

default risky := false

risky = true {
    some i, j
    input.IpPermissions[i].FromPort == 22
    input.IpPermissions[i].ToPort == 22
    input.IpPermissions[i].IpProtocol == "tcp"
    input.IpPermissions[i].IpRanges[j].CidrIp == "0.0.0.0/0"
}