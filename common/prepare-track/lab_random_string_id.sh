#!/bin/bash
##
# this is used as a common string for user and cluster name in the lab session
##
WORK_DIR=/opt/sysdig

function generate_random_id () {

    if [ ! -f $WORK_DIR/random_string_OK ] # random_id not set
    then
        cd prepare-track
        mapfile nouns < ./lab_random_string_id_nouns
        mapfile adjectives < ./lab_random_string_id_adjectives

        nounIndex=$RANDOM%$((${#nouns[@]}-1))
        adjectiveIndex=$RANDOM%$((${#adjectives[@]}-1))

        adjective="$(echo -e "${adjectives[$adjectiveIndex]}" | tr -d '[:space:]')"
        noun="$(echo -e "${nouns[$nounIndex]}" | tr -d '[:space:]')"
        salt="$(shuf -i 1-99999 -n 1)"
        random_id="$adjective"_"$noun"_"$salt"

        echo "${random_id}_student@sysdigtraining.com" > $WORK_DIR/ACCOUNT_PROVISIONED_USER
        #create flag
        echo "$random_id" > $WORK_DIR/random_string_OK
    fi
        random_id=$(cat $WORK_DIR/random_string_OK)
        echo "Random user string from dictionary: $random_id"
}

generate_random_id
