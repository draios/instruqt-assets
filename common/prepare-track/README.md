`init.sh` help
==============

```
USAGE:

  init.sh [OPTIONS...]


Environment start up script. It can be used to deploy a Sysdig Agent and/or set
up some environment variables. When called with NO OPTIONS, it will deploy an
Agent and will ask for Monitor and Secure API keys; same as calling with
'-a/--agent -m/--monitor -s/--secure'. When using the product options"
('-m/--monitor' and/or '-s/--secure'), API keys will be stored in file
/opt/sysdig/user_data_${PRODUCT}_API_OK, and exported to envvar
$SYSDIG_${PRODUCT}_API_TOKEN (where ${PRODUCT} is MONITOR or SECURE).

WARNING: This script is meant to be used in training materials. Do NOT use it
in production.


OPTIONS:

  -a, --agent                 Deploy a Sysdig Agent.
  -h, --help                  Show this help.
  -m, --monitor               Set up environment for Monitor API usage.
  -n, --node-analyzer         Enable Node Analyzer. Use with -a/--agent.
  -N, --node-image-analyzer   Enable Image Node Analyzer. Use with -a/--agent.
  -p, --prometheus            Enable Prometheus. Use with -a/--agent.
  -s, --secure                Set up environment for Secure API usage.


ENVIRONMENT VARIABLES:

  INSTALL_WITH                Sets preferred installation method. Available
                              options are 'helm', 'docker' and 'host'. If not
                              set, it will default to what's available in your,
                              checking first for 'helm', then 'docker', and
                              finally 'host'.

  HELM_OPTS                   Additional options for Helm installation.

  DOCKER_OPTS                 Additional options for Docker installation.

  HOST_OPTS                   Additional options for Host installation.
```