#!/usr/bin/bash

# 
PROJECT_NAME=""
VENUE_NAME=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 --project-name <PROJECT_NAME> --venue-name <VENUE_NAME>"
    exit 1
}

#
# It's mandatory to speciy a valid command arguments
#
if [[ $# -ne 4 ]]; then
  usage
fi

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --venue-name)
            VENUE_NAME="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Check if mandatory options are provided
if [[ -z $PROJECT_NAME ]]; then
    usage
fi
if [[ -z $VENUE_NAME ]]; then
    usage
fi

echo "destroy.sh :: PROJECT_NAME: ${PROJECT_NAME}"
echo "destroy.sh :: VENUE_NAME: ${VENUE_NAME}"

source NIGHTLY.ENV

export STACK_NAME="unity-management-console-${PROJECT_NAME}-${VENUE_NAME}"

## Shutdown Process
#echo"--------------------------------------------------------------------------[PASS]" 
echo "Initiating Cloudformation Teardown..." >> nightly_output.txt
echo "Initiating Cloudformation Teardown..."

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
        echo ""
        echo "Stack teardown exceeded ${MAX_WAIT_TIME} seconds - [FAIL]" >> nightly_output.txt
        echo "Stack teardown exceeded ${MAX_WAIT_TIME} seconds - [FAIL]"

        exit
    fi
done

if [ "$STACK_STATUS" == "TERMINATED" ]
then 
    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Stack Teardown: Completed in ${WAIT_TIME}s - [PASS]" >> nightly_output.txt
    echo "Stack Teardown: Completed in ${WAIT_TIME}s - [PASS]"

fi


