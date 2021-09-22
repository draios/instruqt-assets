#!/bin/bash
echo "Please enter your Sysdig keys."
read -p 'Sysdig Agent key: ' AGENT_KEY
#read -p 'Sysdig Monitor API key: ' KUBE_MONITOR_API_TOKEN # UNUSED ATM
echo
echo "Select your region:"
echo
echo "    1. US East (collector.sysdigcloud.com)"
echo "    2. US West (ingest-us2.app.sysdig.com)"
echo "    3. Europe  (ingest-eu1.app.sysdig.com)"
echo

while [ ! $REGION ]; do
	read -p "Region (1/2/3): " REGION
	
	case "$REGION" in
		1)
			export AGENT_COLLECTOR=collector.sysdigcloud.com
			;;
		2)
			export AGENT_COLLECTOR=ingest-us2.app.sysdig.com
			;;
		3)
			export AGENT_COLLECTOR=ingest-eu1.app.sysdig.com
			;;
		*)
			REGION=""
			;;
	esac
done
echo

export AGENT_KEY
export KUBE_MONITOR_API_TOKEN
export AGENT_COLLECTOR


docker-compose up -d