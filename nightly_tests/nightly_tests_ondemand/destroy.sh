#!/usr/bin/bash

source NIGHTLY.ENV

STACK_NAME=unity-cs-nightly-management-console

## Shutdown Process
echo "Terminating cloudformation stack [$STACK_NAME]" >> nightly_output.txt
echo "Terminating cloudformation stack [$STACK_NAME]" 
aws cloudformation delete-stack --stack-name ${STACK_NAME}

STACK_STATUS=""

while [ -z "$STACK_STATUS" ]
do
    echo "Checking Stack Termination [${STACK_NAME}] Status..." >> nightly_output.txt
    echo "Checking Stack Termination [${STACK_NAME}] Status..."
    aws cloudformation describe-stacks --stack-name ${STACK_NAME} > status.txt
    INSTANCE_STATUS=$(cat status.txt |grep '"StackStatus": \"TERMINATED\"')
    sleep 10
done

echo "Instance [${INSTANCE_ID}] Terminated." >> nightly_output.txt
echo "Instance [${INSTANCE_ID}] Terminated."


