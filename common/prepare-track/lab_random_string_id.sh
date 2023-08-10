#!/bin/bash
##
# this is used as a common string for user and cluster name in the lab session
##

function generate_random_id () {

    if [ ! -f $WORK_DIR/random_string_OK ] # random_id not set
    then
        mapfile nouns < ./lab_random_string_id_nouns
        mapfile adjectives < ./lab_random_string_id_adjectives

        nounIndex=$RANDOM%$((${#nouns[@]}-1))

        adjectiveIndex=$RANDOM%$((${#adjectives[@]}-1))

        adjective="$(echo -e "${adjectives[$adjectiveIndex]}" | tr -d '[:space:]')"
        noun="$(echo -e "${nouns[$nounIndex]}" | tr -d '[:space:]')"

        echo $adjective-$noun | echo $(</dev/stdin)"_student@sysdigtraining.com" > /opt/sysdig/ACCOUNT_PROVISIONED_USER
        #create flag
        touch $WORK_DIR/random_string_OK
    fi
        echo "Random user string from dictionary: "$(cat $WORK_DIR/ACCOUNT_PROVISIONED_USER | sed -r 's/@sysdigtraining.com//')
}

generate_random_id