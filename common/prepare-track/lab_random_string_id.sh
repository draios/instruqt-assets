#!/bin/bash
##
# this is used as a common string for user and cluster name in the lab session
##

function generate_random_id () {

    if [ ! -f $WORK_DIR/random_string_OK ] # random_id not set
    then
        apt install -y wamerican </dev/null
        cp /usr/share/dict/words /tmp/dict
        awk '!/\x27/' /tmp/dict > temp && mv temp /tmp/dict
        awk '!/[A-Z]/'   /tmp/dict > temp && mv temp /tmp/dict
        awk '/[a-z]/'   /tmp/dict > temp && mv temp /tmp/dict
        sed -i 'y/āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙǕǗǙǛ/aaaaeeeeiiiioooouuuuuuuuAAAAEEEEIIIIOOOOUUUUUUUU/' /tmp/dict
        shuf -n2 /tmp/dict | cut -d$'\t' -f1 | tr -s "\n" "_" | echo $(</dev/stdin)"student@sysdigtraining.com" > /opt/sysdig/ACCOUNT_PROVISIONED_USER
        #create flag
        touch $WORK_DIR/random_string_OK
    fi
        echo "Random user string from dictionary: "$(cat $WORK_DIR/ACCOUNT_PROVISIONED_USER | sed -r 's/@sysdigtraining.com//')
}

generate_random_id