#!/bin/bash

# create an alias with
# alias stest.="echo YOUR_SAGENTKEY YOUR_MONITORAPIKEY YOUR_SECUREAPIKEY | xclip -sel clip"
# to easily retrieve all the keys (separated by one space) for this script!!

#global
SEC_URL="https://secure.sysdig.com"
SEC_APIKEY=""
MON_URL="https://app.sysdigcloud.com"
MON_APIKEY=""
LOGPATH="tests.log"


echo "This script is intended to QA and maintain educational resources. Please, ignore its content as it is not training related."

# access info
read -r SAGENTKEY MON_APIKEY SEC_APIKEY TRASH

#Step01.md
echo ""
echo "Starting test..."
echo ""

cd ~/
touch $LOGPATH

wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip &> ${LOGPATH}
unzip terraform_0.12.24_linux_amd64.zip -d /usr/local/bin/ &> ${LOGPATH}

mkdir -p ~/.terraform.d/plugins/
wget https://github.com/draios/terraform-provider-sysdig/releases/download/v0.2.1/terraform-provider-sysdig-linux-amd64.tar.gz &> ${LOGPATH}
tar -xzvf terraform-provider-sysdig-linux-amd64.tar.gz -C ~/.terraform.d/plugins/ &> ${LOGPATH}

touch terraform.tfvars
echo "sysdig_secure_api_token=\"${SEC_APIKEY}\"" > terraform.tfvars
echo "sysdig_monitor_api_token=\"${MON_APIKEY}\"" >> terraform.tfvars

sleep 3

#Step02.md
sed -i "s|myemail@sample.com|training-team@sysdig.com|g" sysdig-config.tf 

sleep 3

#Step03.md
terraform init &> ${LOGPATH}
terraform apply -auto-approve &> ${LOGPATH}
EXITCODETERRAFORMAPPLY=$(echo $?) 

echo -n "Testing if Terraform init worked..."
if [ $EXITCODETERRAFORMAPPLY == 0 ]; then
  echo "OK"
else
  echo "FAIL"
fi


# Test resources were created

#notification channel
RESOURCE_NAME="Example Channel (from Terraform)"
curl -s -H 'Authorization: Bearer '"${SEC_APIKEY}" "${SEC_URL}"'/api/notificationChannels?searchFilter=&sortBy=type&sortDirection=asc' | jq '.notificationChannels[]? | {id: .id, name: .name ,}' | grep "$RESOURCE_NAME" &> ${LOGPATH}
RESULT=$?

echo -n "Testing if resource NOTIFICATION CHANNEL was created..."
if [ $RESULT -eq 0 ]; then
	echo "OK"
else
	echo "FAIL"
fi

# rule
RESOURCE_NAME="Example Container Rule (from Terraform)"
curl -s -H 'Authorization: Bearer '"${SEC_APIKEY}" "${SEC_URL}"'/api/secure/rules/summaries?searchFilter=&sortBy=type&sortDirection=asc' | jq '.[]? | {id: .id, name: .name ,}' | grep "$RESOURCE_NAME" &> ${LOGPATH}
RESULT=$?

echo -n "Testing if resource RULE was created..."
if [ $RESULT -eq 0 ]; then
	echo " OK"
else
	echo "FAIL"
fi

#policy
RESOURCE_NAME="Example Policy (from Terraform)"
curl -s -H 'Authorization: Bearer '"${SEC_APIKEY}" "${SEC_URL}"'/api/v2/policies/?searchFilter=&sortBy=type&sortDirection=asc' | jq '.[]? | {id: .id, name: .name ,}'  | grep "$RESOURCE_NAME" &> ${LOGPATH}
RESULT=$?

echo -n "Testing if resource POLICY was created..."
if [ $RESULT -eq 0 ]; then
	echo " OK"
else
	echo "FAIL"
fi

sleep 3

#Step04.md

if [ $EXITCODETERRAFORMAPPLY == 0 ]; then
  terraform destroy -auto-approve &> ${LOGPATH}
  EXITCODETERRAFORMDESTROY=$(echo $?) 
  echo -n "Testing if Terraform destroy worked..."
  if [ $EXITCODETERRAFORMDESTROY == 0 ]; then
    echo "OK"
  else
    echo "FAIL"
  fi
fi


# Test resources were deleted. 

#notification channel
RESOURCE_NAME="Example Channel (from Terraform)"
curl -s -H 'Authorization: Bearer '"${SEC_APIKEY}" "${SEC_URL}"'/api/notificationChannels?searchFilter=&sortBy=type&sortDirection=asc' | jq '.notificationChannels[]? | {id: .id, name: .name ,}' | grep "$RESOURCE_NAME" &> ${LOGPATH}
RESULT=$?

echo -n "Testing if resource NOTIFICATION CHANNEL was deleted..."
if [ $RESULT -eq 0 ]; then
	echo "FAIL"
else
	echo "OK"
fi

# rule
RESOURCE_NAME="Example Container Rule (from Terraform)"
curl -s -H 'Authorization: Bearer '"${SEC_APIKEY}" "${SEC_URL}"'/api/secure/rules/summaries?searchFilter=&sortBy=type&sortDirection=asc' | jq '.[]? | {id: .id, name: .name ,}' | grep "$RESOURCE_NAME" &> ${LOGPATH}
RESULT=$?

echo -n "Testing if resource RULE was deleted..."
if [ $RESULT -eq 0 ]; then
	echo "FAIL"
else
	echo "OK"
fi

#policy
RESOURCE_NAME="Example Policy (from Terraform)"
curl -s -H 'Authorization: Bearer '"${SEC_APIKEY}" "${SEC_URL}"'/api/v2/policies/?searchFilter=&sortBy=type&sortDirection=asc' | jq '.[]? | {id: .id, name: .name ,}'  | grep "$RESOURCE_NAME" &> ${LOGPATH}
RESULT=$?

echo -n "Testing if resource POLICY was deleted..."
if [ $RESULT -eq 0 ]; then
	echo "FAIL"
else
	echo "OK"
fi

echo ""
echo "Test completed"
echo ""