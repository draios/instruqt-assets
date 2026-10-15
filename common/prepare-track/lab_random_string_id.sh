#!/bin/bash
##
# this is used as a common string for user and cluster name in the lab session
#
# POV_MODE=true (default in this branch):
#   random id : <adjective>_<noun>
#   user      : <adjective>_<noun>+pov@sysdig.com  (first name <adjective>, last name <noun>)
#   cluster   : <adjective>_<noun>_pov_cluster      (see deploy_agent in init.sh)
# POV_MODE=false (training labs, previous naming):
#   random id : <adjective>_<noun>_<salt>
#   user      : <random id>_student@sysdig.com
#   cluster   : <random id>_<deploy date>
##
WORK_DIR=/opt/sysdig
POV_MODE="${POV_MODE:-true}"
# directory holding the word lists (absolute, so the function can run more than once)
LAB_ID_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

function generate_random_id () {

    if [ ! -f $WORK_DIR/random_string_OK ] # random_id not set
    then
        cd "$LAB_ID_DIR"
        mapfile nouns < ./lab_random_string_id_nouns
        mapfile adjectives < ./lab_random_string_id_adjectives

        nounIndex=$RANDOM%$((${#nouns[@]}-1))
        adjectiveIndex=$RANDOM%$((${#adjectives[@]}-1))

        adjective="$(echo -e "${adjectives[$adjectiveIndex]}" | tr -d '[:space:]')"
        noun="$(echo -e "${nouns[$nounIndex]}" | tr -d '[:space:]')"

        if [ "$POV_MODE" = true ]
        then
            random_id="$adjective"_"$noun"
            echo "${random_id}+pov@sysdig.com" > $WORK_DIR/ACCOUNT_PROVISIONED_USER
        else
            salt="$(shuf -i 1-99999 -n 1)"
            random_id="$adjective"_"$noun"_"$salt"
            echo "${random_id}_student@sysdig.com" > $WORK_DIR/ACCOUNT_PROVISIONED_USER
        fi
        #create flag
        echo "$random_id" > $WORK_DIR/random_string_OK
    fi
        random_id=$(cat $WORK_DIR/random_string_OK)
        echo "Random user string from dictionary: $random_id"
}

generate_random_id
