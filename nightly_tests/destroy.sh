# TODO: DELETE THIS FILE
#!/usr/bin/bash

source NIGHTLY.ENV

## Shutdown Process
echo "Terminating instance [$INSTANCE_ID]" >> nightly_output.txt
echo "Terminating instance [$INSTANCE_ID]" 
aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}

INSTANCE_STATUS=""

while [ -z "$INSTANCE_STATUS" ]
do
   echo "Checking Instance Termination [${INSTANCE_ID}] Status..." >> nightly_output.txt
   echo "Checking Instance Termination [${INSTANCE_ID}] Status..."
   aws ec2 describe-instance-status --instance-id $INSTANCE_ID > status.txt
   INSTANCE_STATUS=$(cat status.txt |grep '"InstanceStatuses": \[\]')
   sleep 10
done

echo "Instance [${INSTANCE_ID}] Terminated." >> nightly_output.txt
echo "Instance [${INSTANCE_ID}] Terminated."

