#!/bin/bash
# QAtraining
# scrape-prometheus-metrics-with-sysdig

echo "This script is intended to QA and maintain educational resources. Please, ignore its content as it is not training related."

# keys and not storable info
read -s -p "Enter your Sysdig Agent Key, Sysdig Monitor API and Sysdig Secure API: " SAK SAM SAS TRASH

# step01 ------------------------------------------------------------------------------------------------------------

echo "-----Spinning up nginx-server"

cd nginx && cat docker-compose.yml
docker-compose up -d
curl -s localhost:8000
curl -s localhost:8000/metrics

if [ $? -eq 0 ]; then
	echo "-----nginx-server OK"
else
	echo "-----nginx-server BROKEN"
fi

# step02 ------------------------------------------------------------------------------------------------------------

echo "-----Spinning up nginx-exporter"

cat <<- 'EOF' >> "docker-compose.yml"
    nginx-exporter:
        container_name: nginx-exporter
        image: nginx/nginx-prometheus-exporter:0.5.0
        restart: always
        command: -nginx.scrape-uri http://nginx:80/metrics -nginx.retries 50 -nginx.retry-interval 10s
        ports:
            - "9113:9113"
        labels:
            - "io.prometheus.scrape=true"    
            - "io.prometheus.port=9113"
EOF

docker-compose down && docker-compose up -d

sleep 10

curl -s localhost:9113/metrics
if [ $? -eq 0 ]; then
	echo "nginx-exporter OK"
else
	echo "nginx-exporter BROKEN, logs:"
	docker logs nginx-exporter
fi

# step03 ------------------------------------------------------------------------------------------------------------

echo "-----Spinning up sysdig-agent"

cd ../sysdig-agent
#cat -n docker-compose.yml
#cat -n dragent.yaml

# step04 ------------------------------------------------------------------------------------------------------------

export AGENT_KEY=$SAK
docker-compose up -d
sleep 45
docker ps
#best way to test this would be, apart from findingthe agent linked, retreving the nginx metrics in the Sysdig Prometheus endpoint

SYSDIG_MONITOR_URL="https://app.sysdigcloud.com"
SYSDIG_MONITOR_TOKEN=$SAM

#check the number of agent in the account
NAGENTS=$(curl -H 'Authorization: Bearer '"${SYSDIG_TOKEN}" "${SYSDIG_URL}"'/api/agents/connected?searchFilter=&sortBy=type&sortDirection=asc' | jq '.total')
echo "There are ${NAGENTS} agent(s) connected to your account"

#check with the hostname (in katacoda it is normally host01, host02, etc.), also possible with version of the agent.
DATE=$(date +%s)
TIMETO=$(( $DATE ))
TIMETO=${TIMETO%?}
TIMETO+=0
TIMEFROM=$(( $TIMETO - 60 ))
#echo "DATE: " $DATE "TIMETO: " $TIMETO "TIMEFROM: " $TIMEFROM
TIMETO+=000000
TIMEFROM+=000000
EXPECTED=host01
cp data.json.original data.json
sed -i -e 's/"_TO"/'"$TIMETO"'/g' data.json
sed -i -e 's/"_FROM"/'"$TIMEFROM"'/g' data.json

echo -n "Testing agent installation on host ${EXPECTED}: "

#agent
RESULT=$(curl -s --header "Content-Type: application/json"   \
        -H 'Authorization: Bearer '"${SYSDIG_MONITOR_TOKEN}" \
        --request POST \
        --data @./data.json \
        "${SYSDIG_MONITOR_URL}"/api/data/batch \
        | jq ".responses[].data[]" | grep -o "pablopez" )

[ "$RESULT" = "$EXPECTED" ] && echo "AGENT WORKING" || echo "AGENT WRONG"

rm data.json

echo "simulating HTTP requests to server"
cd ../nginx && ./test.sh

# step05 ------------------------------------------------------------------------------------------------------------
