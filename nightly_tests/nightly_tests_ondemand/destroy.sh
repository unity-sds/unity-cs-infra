#!/usr/bin/bash

source NIGHTLY.ENV

STACK_NAME=unity-cs-nightly-management-console

## Shutdown Process
echo "Terminating cloudformation stack [$STACK_NAME]" >> nightly_output.txt
echo "Terminating cloudformation stack [$STACK_NAME]" 
aws cloudformation delete-stack --stack-name ${STACK_NAME}

STACK_STATUS=""

WAIT_TIME=0
MAX_WAIT_TIME=100
WAIT_BLOCK=20

while [ -z "$STACK_STATUS" ]
do
    echo "Checking Stack Termination [${STACK_NAME}] Status after ${WAIT_TIME} seconds..." >> nightly_output.txt
    echo "Checking Stack Termination [${STACK_NAME}] Status after ${WAIT_TIME} seconds..."
    aws cloudformation describe-stacks --stack-name ${STACK_NAME} > status.txt
    STACK_STATUS=$(cat status.txt |grep '"StackStatus": \"TERMINATED\"')
    sleep $WAIT_BLOCK
    WAIT_TIME=$(($WAIT_BLOCK + $WAIT_TIME))
    if [ "$WAIT_TIME" -gt "$MAX_WAIT_TIME" ] 
    then
        echo "ERROR: Cloudformation Stack [${STACK_NAME}] Has not terminated after ${MAX_WAIT_TIME} seconds." >> nightly_output.txt
        echo "ERROR: Cloudformation Stack [${STACK_NAME}] Has not terminated after ${MAX_WAIT_TIME} seconds."
        exit
    fi
done

echo "Cloudformation Stack [${STACK_NAME}] Terminated." >> nightly_output.txt
echo "Cloudformation Stack [${STACK_NAME}] Terminated."


