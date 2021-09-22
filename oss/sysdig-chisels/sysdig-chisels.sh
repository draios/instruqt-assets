!#/bin/bash

CHISEL=${1}
ARGS=${2}
# run a container mounting a custom chisel
docker run -i -t --name sysdig \
    --privileged \
    -v /var/run/docker.sock:/host/var/run/docker.sock \
    -v /dev:/host/dev \
    -v /proc:/host/proc:ro \
    -v /boot:/host/boot:ro \
    -v /lib/modules:/host/lib/modules:ro \
    -v /usr:/host/usr:ro \
    -v ${CHISEL}:/usr/share/sysdig/chisels/my_chisel.lua \
sysdig/sysdig

wait 2

# run the chisel
sysdig -c my_chisel.lua ${ARGS}
