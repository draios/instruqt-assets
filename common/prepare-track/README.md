`init.sh` help
==============

```
USAGE:

  init.sh [OPTIONS...]


Environment start up script. It can be used to:
- deploy a Sysdig Agent 
- deploy Sysdig Secure for Cloud (AWS, GCP, Azure)
- and/or set up some environment variables.

Review the options below to learn what's available.

WARNING: This script is meant to be used in training materials.
Do NOT use it in production.


OPTIONS:

  -a, --agent                 Deploy a Sysdig Agent.
  -c, --cloud                 Set up environment for Sysdig Secure for Cloud.
  -h, --help                  Show this help.
  -m, --monitor               Set up environment for Monitor API usage.
  -n, --node-analyzer         Enable Node Analyzer. Use with -a/--agent.
  -N, --node-image-analyzer   Enable Image Node Analyzer. Use with -a/--agent.
  -p, --prometheus            Enable Prometheus. Use with -a/--agent.
  -s, --secure                Set up environment for Secure API usage.
  -r, --region                Set up environment with user's Sysdig Region for a track with a host.
  -q, --region-cloud          Set up environment with user's Sysdig Region for cloud track with a cloud account.
  -v, --vulnmanag             Enable Image Scanning with Sysdig Secure for Cloud. Use with -c/--cloud.

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