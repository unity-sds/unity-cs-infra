#!/usr/bin/bash

source ./NIGHTLY.ENV

export SSH_KEY="~/.ssh/ucs-nightly.pem"

INSTANCE_ID=$(cat instance.id)

echo "Private IP Address: [$IP_ADDRESS]" >> nightly_output.txt
echo "Private IP Address: [$IP_ADDRESS]"

echo "Public IP Address: [$IP_ADDRESS_PUBLIC]" >> nightly_output.txt
echo "Public IP Address: [$IP_ADDRESS_PUBLIC]"


ssh -i $SSH_KEY -o 'StrictHostKeyChecking no' ubuntu@$IP_ADDRESS 'exit'

ssh -i $SSH_KEY ubuntu@$IP_ADDRESS "ls -al"

ssh -i $SSH_KEY ubuntu@$IP_ADDRESS "wget https://github.com/unity-sds/unity-management-console/releases/download/0.2.12/managementconsole.zip"

echo "Starting up the management console webapp in the background" >> nightly_output.txt
echo "Starting up the management console webapp in the background"

ssh -i $SSH_KEY  ubuntu@$IP_ADDRESS "unzip -o managementconsole.zip; cd management-console; nohup ./main webapp &" &

sleep 5

LOGIN_MESSAGE=$(wget http://$IP_ADDRESS:8080 2>&1 |grep 'Authentication Failed')

if [ -z "$LOGIN_MESSAGE" ]
then
    echo "Login Message is empty, service did not stand up" >> nightly_output.txt
    echo "Login Message is empty, service did not stand up"
else
    echo "Managment Console is up but requires authentication" >> nightly_output.txt
    echo "Managment Console is up but requires authentication"
fi


echo "Endpoint: [http://${IP_ADDRESS_PUBLIC}:8080/ui/]" >> nightly_output.txt
echo "Endpoint: [http://${IP_ADDRESS_PUBLIC}:8080/ui/]"
