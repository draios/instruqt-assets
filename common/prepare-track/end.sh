#!/usr/bin/env bash
###
# Sysdig Agent and cloud_infra deploy helper for Sysdig Training tracks.
#
# AUTHORS:
#   Sysdig Education Team <team-training@sysdig.com>
#
#   Current SaaS regions: https://docs.sysdig.com/en/docs/administration/saas-regions-and-ip-ranges/
###

trap '' 2 # Signal capture quit with Ctrl+C


###########################    GLOBAL CONSTANTS    ############################
F_BOLD='\e[1m'
F_RED='\x1B[31m'
F_CYAN='\e[36m'
F_CLEAR='\e[0m'

WORK_DIR=/opt/sysdig
TRACK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P )
AGENT_CONF_DIR=/root/sysdig-agent

TITLE="Sysdig Agent uninstallation"

##############################    GLOBAL VARS    ##############################
INSTALL_WITH=''
MONITOR_URL=''
SECURE_URL=''
AGENT_COLLECTOR=''
NIA_ENDPOINT=''
SKIP_CLEANUP=false

USE_USER_PROVISIONER=false
USE_AGENT=false
USE_MONITOR_API=false
USE_SECURE_API=false
USE_NODE_ANALYZER=false
USE_KSPM=false
USE_PROMETHEUS=false
USE_RAPID_RESPONSE=false
USE_K8S=false
USE_CLOUD=false
USE_CLOUD_SCAN_ENGINE=false
USE_CLOUD_REGION=false
USE_AGENT_REGION=false
USE_RUNTIME_VM=false
USE_CURSES=false

###############################    FUNCTIONS    ###############################
##
# Message to display when ran into an issue
##
function panic_msg () {
    echo
    echo "Some errors were detected configuring this lab."
    echo "To restart the config of the environment, reload the terminal window (top right corner of the lab)."
    echo
    echo "You can ask for help using Intercom or get in touch with us at team-training@sysdig.com"
    exit 1
}

function track_has_cloud_account () {
    if [ ! -z "$INSTRUQT_AWS_ACCOUNTS" ]
    then
        CLOUD_PROVIDER=aws
        cloudvarname=INSTRUQT_AWS_ACCOUNT_${INSTRUQT_AWS_ACCOUNTS}_ACCOUNT_ID
        CLOUD_ACCOUNT_ID=${!cloudvarname}
    fi

    if [ ! -z "$INSTRUQT_GCP_PROJECTS" ]
    then
        CLOUD_PROVIDER=gcp
        cloudvarname=INSTRUQT_GCP_PROJECT_${INSTRUQT_GCP_PROJECTS}_PROJECT_ID
        CLOUD_ACCOUNT_ID=${!cloudvarname}

        # terraform config to use the service account with role.owner permissions.
        # the user account provided by instruqt do not have org-level permissions and these
        # are required for the sysdig-cloud GCP installer
        sakeyvarname=INSTRUQT_GCP_PROJECT_${INSTRUQT_GCP_PROJECTS}_SERVICE_ACCOUNT_KEY
        SA_KEY=${!sakeyvarname}
        echo $SA_KEY | base64 -d > creds.json # credentials for the Service Account
        export TF_VAR_project=$CLOUD_ACCOUNT_ID
        grep $CLOUD_ACCOUNT_ID /root/.bashrc || echo "export TF_VAR_project=\"$CLOUD_ACCOUNT_ID\"" >> /root/.bashrc

        # set the path for terraform to use the service account credentials
        export GOOGLE_CREDENTIALS=$(pwd)/creds.json
        echo "export GOOGLE_CREDENTIALS=$GOOGLE_CREDENTIALS" >> /root/.bashrc
    fi

    if [ ! -z "$INSTRUQT_AZURE_SUBSCRIPTIONS" ]
    then
        CLOUD_PROVIDER=azure
        cloudvarname=INSTRUQT_AZURE_SUBSCRIPTION_${INSTRUQT_AZURE_SUBSCRIPTIONS}_SUBSCRIPTION_ID
        CLOUD_ACCOUNT_ID=${!cloudvarname}
    fi

    if [ -z $CLOUD_PROVIDER ]
    then
        echo "  FAIL"
        echo "  This track does not include a cloud account but it should."
        panic_msg
    fi
}

##
# Deploys the cloud bench.
##

function remove_cloud_bench () {
    CLOUD_BENCH_REMOVAL_DATE=$(date -d '+2 hour' +"%F__%H_%M")
    CLOUD_BENCH_REMOVAL_QUERY=$(date +"%FT%H:%M:%S") # get a removal date that matches the format and timezone of the date returned by sysdig API CloudProvidersLastSeen
    CLOUD_REGION=""
    echo ${CLOUD_BENCH_REMOVAL_DATE} > $WORK_DIR/cloud_bench_removal_date
    echo ${CLOUD_BENCH_REMOVAL_QUERY} > $WORK_DIR/cloud_bench_removal_query
    
    echo "Removing Cloud-Bench integration for $CLOUD_PROVIDER"

    # we are defining here some values (region) but in future we might want the user to choose its region
    # right now there's not a reason to select one or another
    if [ $CLOUD_PROVIDER = "aws" ]
    then
        CLOUD_REGION="us-east-1"
    elif [ $CLOUD_PROVIDER = "gcp" ]
    then
        CLOUD_REGION="us-east1"
    elif [ $CLOUD_PROVIDER = "azure" ]
    then
        CLOUD_REGION="foo"
    fi

    echo -e " Cloud-Bench is being uninstalled in the background.\n"

    SYSDIG_SECURE_API_TOKEN=$(cat /opt/sysdig/user_data_SECURE_API_OK)
    SECURE_API_ENDPOINT=$(cat /opt/sysdig/SECURE_API_ENDPOINT)

    echo source $TRACK_DIR/cloud/uninstall_with_terraform.sh $CLOUD_PROVIDER $SYSDIG_SECURE_API_TOKEN $SECURE_API_ENDPOINT $CLOUD_REGION $CLOUD_ACCOUNT_ID

    source $TRACK_DIR/cloud/uninstall_with_terraform.sh $CLOUD_PROVIDER $SYSDIG_SECURE_API_TOKEN $SECURE_API_ENDPOINT $CLOUD_REGION $CLOUD_ACCOUNT_ID
}

##
# Test if the Cloud account is connected successfully.
##
function test_cloud_bench () {
    echo "    Testing if the cloud account is not connected..."

    attempt=0
    MAX_ATTEMPTS=36 # 6 minutes
    HTTP_RESPONSE=200
    while [ ${HTTP_RESPONSE} -ne 404 ] && [ ${attempt} -lt ${MAX_ATTEMPTS} ]
    do
        sleep 10

        HTTP_RESPONSE=$(curl --head -s --header "Content-Type: application/json" \
          -H 'Authorization: Bearer '"${SYSDIG_SECURE_API_TOKEN}" \
          --request GET \
          ${SECURE_API_ENDPOINT}/api/cloud/v2/accounts/${CLOUD_ACCOUNT_ID} | awk '/^HTTP/{print $2}')
        
        attempt=$(( $attempt + 1 ))
    done

    if [ "$HTTP_RESPONSE" -eq "404" ]
    then
        echo "  Sysdig integration successfully disconnected."
        curl -s --header "Content-Type: application/json" \
          -H 'Authorization: Bearer '"${SYSDIG_SECURE_API_TOKEN}" \
          --request GET \
          ${SECURE_API_ENDPOINT}/api/cloud/v2/accounts/${CLOUD_ACCOUNT_ID}
        rm $WORK_DIR/user_data_CLOUDBENCH_OK
    else
        echo "  FAIL"
        echo "  Cloud Bench integration went wrong. Use the provided channels to report this issue."
        panic_msg
    fi
}

##
# Delete files only needed while running the script.
##
##
# Check and consume script flags.
##
function check_flags () {
    while [ ! $# -eq 0 ]
    do
        case "$1" in
            --skip-cleanup)
                SKIP_CLEANUP=true
                ;;
            --provision-user)
                USE_USER_PROVISIONER=true
                ;;
            --agent | -a)
                USE_AGENT=true
                USE_AGENT_REGION=true
                ;;
            --region | -r)
                USE_AGENT_REGION=true
                ;;
            --cloud | -c)
                USE_CLOUD=true
                USE_CLOUD_REGION=true
                USE_SECURE_API=true
                ;;
            --region-cloud | -q)
                USE_CLOUD_REGION=true
                ;;
            --monitor | -m)
                USE_MONITOR_API=true
                ;;
            --secure | -s)
                USE_SECURE_API=true
                ;;
            --node-analyzer | -n)
                export USE_NODE_ANALYZER=true
                ;;
            --kspm | -k)
                export USE_KSPM=true
                ;;
            --prometheus | -p)
                export USE_PROMETHEUS=true
                ;;
            --rapid-response | -b)
                export USE_RAPID_RESPONSE=true
                ;;
            --vuln-management | -v)
                export USE_CLOUD_SCAN_ENGINE=true
                ;;
            --use-curses | -x)
                export USE_CURSES=true
                ;;
            --kube-adm | -8)
                export USE_K8S=true
                ;;
            --runtime-vm)
                export USE_RUNTIME_VM=true
                ;;
            --help | -h)
                help
                exit 0
                ;;
            *)
                echo "Unkown argument: $1"
                help
                exit 1
                ;;
        esac
        shift
    done

    if ([ "$USE_NODE_ANALYZER" = true ] || [ "$USE_PROMETHEUS" = true ] || [ "$USE_RUNTIME_VM" = true ]  || [ "$USE_RAPID_RESPONSE" = true ]  || [ "$USE_K8S" = true ]) && [ "$USE_AGENT" != true ]
    then
        echo "ERROR: Options only available with -a/--agent."
        exit 1
    fi

}

##
# Execute setup.
##
function setup () {
    mkdir -p $WORK_DIR/

    check_flags $@

    if [ "$USE_CLOUD" = true ]
    then
        # we can't run `track_has_cloud_account` and `deploy_cloud_connector`
        # before `configure_API` because they use data set within `configure_API`
        track_has_cloud_account
        remove_cloud_bench
        test_cloud_bench
    fi
}

################################    SCRIPT    #################################
setup $@
