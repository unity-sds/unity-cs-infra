#!/usr/bin/bash

source NIGHTLY.ENV

STACK_NAME=unity-cs-nightly-management-console

## Shutdown Process
#echo"--------------------------------------------------------------------------[PASS]" 
echo "Beginning Cloudformation Teardown........................................." >> nightly_output.txt
echo "Beginning Cloudformation Teardown........................................."

aws cloudformation delete-stack --stack-name ${STACK_NAME}

STACK_STATUS=""

WAIT_TIME=0
MAX_WAIT_TIME=2400
WAIT_BLOCK=20

while [ -z "$STACK_STATUS" ]
do

    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Waiting for Cloudformation Stack Termination..............................[$WAIT_TIME]"

    aws cloudformation describe-stacks --stack-name ${STACK_NAME} > status.txt
    STACK_STATUS=""
    if [ -s status.txt ]
    then
        STACK_STATUS=""
    else
        STACK_STATUS="TERMINATED"
    fi

    sleep $WAIT_BLOCK
    WAIT_TIME=$(($WAIT_BLOCK + $WAIT_TIME))
    if [ "$WAIT_TIME" -gt "$MAX_WAIT_TIME" ] 
    then
        #echo"--------------------------------------------------------------------------[PASS]" 
        echo "Cloudformation Stack destroyed under $MAX_WAIT_TIME seconds.........................[FAIL]" >> nightly_output.txt
        echo "Cloudformation Stack destroyed under $MAX_WAIT_TIME seconds.........................[FAIL]"

        exit
    fi
done

if [ "$STACK_STATUS" == "TERMINATED" ]
then 
    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Cloudformtion Stack Terminated in ${WAIT_TIME} seconds............................[PASS]" >> nightly_output.txt
    echo "Cloudformtion Stack Terminated in ${WAIT_TIME} seconds............................[PASS]"

fi


