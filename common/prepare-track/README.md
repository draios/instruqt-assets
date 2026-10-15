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

  --skip-cleanup              Skip script setup clean-up actions.
  --provision-user            Creates user in Sysdig Saas Training account for use in this lab.
  --dynamic-setup             Do not use the user provisioner, use the runtime parameters.
  --wait                      Make the Helm installation wait until the agent is ready.
  -a, --agent                 Deploy a Sysdig Agent.
  -A, --all-features          Enable every Sysdig Shield feature (admission control in enforce
                              mode, posture, vulnerability management, detections, investigations,
                              response actions). Use with -a/--agent. Works for SaaS and on-prem.
  -b, --rapid-response        Enable Rapid Response
  -c, --cloud                 Set up environment for Sysdig Secure for Cloud.
  -h, --help                  Show this help.
  -j, --admission-controller  Enable Admission Controller. Use with -a/--agent.
  -k, --kspm                  Enable KSPM. Use with -a/--agent.
  -m, --monitor               Set up environment for Monitor API usage.
  -n, --node-analyzer         Enable Node Analyzer. Use with -a/--agent.
  -p, --prometheus            Enable Prometheus. Use with -a/--agent.
  -q, --region-cloud          Set up environment with user's Sysdig Region for cloud track with a cloud account.
  -r, --region                Set up environment with user's Sysdig Region for a track with a host.
  -s, --secure                Set up environment for Secure API usage.
  -v, --vuln-management       Enable Image Scanning with Sysdig Secure for Cloud. Use with -c/--cloud.
  -x, --use-curses            Use ncurses dialog menus instead of CLI.
  -8, --kube-adm              Customize installer for kubeadm k8s cluster
  --on-prem <url>             On-prem backend URL (region 7), e.g. https://sysdig.example.com
      --collector <host[:port]>  On-prem agent collector (region 7). Defaults to the backend host, port 6443.
      --response-actions      Enable Response Actions. Use with -a/--agent.
      --runtime-vm            Enable VM Runtime Scanner. Use with --node-analyzer.
      --no-check              Remove agent and cloud connector post install health check.


ENVIRONMENT VARIABLES:

  INSTALL_WITH                Sets preferred installation method. Available
                              options are 'helm', 'docker' and 'host'. If not
                              set, it will default to what's available in your,
                              checking first for 'helm', then 'docker', and
                              finally 'host'.

  HELM_OPTS                   Additional options for Helm installation.

  DOCKER_OPTS                 Additional options for Docker installation.

  HOST_OPTS                   Additional options for Host installation.

  DYNAMIC_SETUP               Set to 'true' to skip interactive prompts and use
                              the TEST_* / DYNAMIC_* env vars below instead.
                              Can be set via Instruqt invite env-var overrides.

  DYNAMIC_AGENT_ACCESS_KEY    Base64-encoded Sysdig Agent access key.
                              Overrides TEST_AGENT_ACCESS_KEY.

  DYNAMIC_MONITOR_API         Base64-encoded Sysdig Monitor API token.
                              Overrides TEST_MONITOR_API.

  DYNAMIC_SECURE_API          Base64-encoded Sysdig Secure API token.
                              Overrides TEST_SECURE_API.

  TEST_REGION                 Region number used in non-interactive/dynamic mode.
                              Defaults to 2 (US West AWS - us2). Values:
                                1  US East (Virginia) - us1
                                2  US West AWS (Oregon) - us2
                                3  US West GCP (Dallas) - us4
                                4  European Union (Frankfurt) - eu1
                                5  AP Australia (Sydney) - au1
                                6  AP Cybereason (Sydney) - au1
                                7  On Premises (requires DYNAMIC_MONITOR_API_URL
                                   or DYNAMIC_SECURE_API_URL)
                                8  European Union (Stockholm) - eu2
                                9  Middle East (Dammam) - me2
                                10 AP South (Mumbai) - in1
                                11 AP Japan (Tokyo) - jp1

  DYNAMIC_MONITOR_API_URL     Base URL of the on-prem Sysdig backend
                              (e.g. https://sysdig.corp.example.com).
                              Required when TEST_REGION=7 in dynamic/test mode.
                              Takes precedence over DYNAMIC_SECURE_API_URL.

  DYNAMIC_SECURE_API_URL      Base URL of the on-prem Sysdig Secure backend.
                              Fallback for DYNAMIC_MONITOR_API_URL when TEST_REGION=7.

  DYNAMIC_COLLECTOR_HOST      On-prem agent collector, "host" or "host:port".
                              Defaults to the host of the backend URL.

  DYNAMIC_COLLECTOR_PORT      On-prem agent collector port. Defaults to 6443.

  POV_MODE                    'true' (default in this branch) names the provisioned user
                              <adjective>_<noun>+pov@sysdig.com (admin, Secure only) and the
                              cluster <adjective>_<noun>_pov_cluster. 'false' restores the
                              training naming (<adjective>_<noun>_<salt>, student user).

```
