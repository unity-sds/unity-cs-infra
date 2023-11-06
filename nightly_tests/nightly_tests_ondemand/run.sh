#!/bin/sh
export STACK_NAME="unity-cs-nightly-management-console"

## Retrieve the github token from SSM
export SSM_GITHUB_TOKEN="/unity-sds/u-cs/nightly/githubtoken"
export SSM_MC_USERNAME="/unity/ci/mc_username"
export SSM_MC_PASSWORD="/unity/ci/mc_password"
export SSM_SLACK_URL="/unity/ci/slack-web-hook-url"
export MC_USERNAME=$(aws ssm get-parameter           --name ${SSM_MC_USERNAME}       |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
export MC_PASSWORD=$(aws ssm get-parameter           --name ${SSM_MC_PASSWORD}       |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
SLACK_URL=$(aws ssm get-parameter           --name ${SSM_SLACK_URL}       |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')

GITHUB_TOKEN=$(aws ssm get-parameter          --name ${SSM_GITHUB_TOKEN}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')

if [ -z "$GITHUB_TOKEN" ] 
then 
    echo "ERROR: Could not read Github Token from SSM.  Does the key [$SSM_GITHUB_TOKEN] exist?"
    exit
fi


rm -f nightly_output.txt
rm -f cloudformation_events.txt


NIGHTLY_HASH=$(git rev-parse --short HEAD)
#echo "Using nightly test repo commit [$NIGHTLY_HASH]" >> nightly_output.txt
#echo"--------------------------------------------------------------------------[PASS]"
echo "Retrieving Nightly Test Repo Hash.........................................[$NIGHTLY_HASH]" >> nightly_output.txt
echo "Retrieving Nightly Test Repo Hash.........................................[$NIGHTLY_HASH]"

## update self
git pull origin main

## update cloudformation scripts
rm -rf cloudformation
git clone https://oauth2:$GITHUB_TOKEN@github.com/unity-sds/cfn-ps-jpl-unity-sds.git cloudformation
cd cloudformation
CLOUDFORMATION_HASH=$(git rev-parse --short HEAD)
cd ..
#echo "Using cfn-ps-jpl-unity-sds repo commit [$CLOUDFORMATION_HASH]" >> nightly_output.txt
#echo"--------------------------------------------------------------------------[PASS]"
echo "Retrieving Cloudformation Repo Hash.......................................[$CLOUDFORMATION_HASH]" >> nightly_output.txt
echo "Retrieving Cloudformation Repo Hash.......................................[$CLOUDFORMATION_HASH]"

cp ./cloudformation/templates/unity-mc.main.template.yaml template.yml




bash deploy.sh
#bash step2.sh &


aws cloudformation describe-stack-events --stack-name ${STACK_NAME} >> cloudformation_events.txt

# run selenium test on management console
export MANAGEMENT_CONSOLE_URL=$(aws cloudformation describe-stacks --stack-name unity-cs-nightly-management-console --query "Stacks[0].Outputs[?OutputKey=='ManagementConsoleURL'].OutputValue" --output text)
echo "$MC_USERNAME"
echo "$MC_PASSWORD"
echo "$MANAGEMENT_CONSOLE_URL"

sudo docker pull selenium/standalone-chrome
sudo docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-chrome
sleep 10

python3 selenium_test_management_console.py 
# sleep 10
# bash destroy.sh
# 
# #cat nightly_output.txt
# 
# OUTPUT=$(cat nightly_output.txt)
# 
# 
# cat cloudformation_events.txt |sed 's/\s*},*//g' |sed 's/\s*{//g' |sed 's/\s*\]//' |sed 's/\\"//g' |sed 's/"//g' |sed 's/\\n//g' |sed 's/\\/-/g' |sed 's./.-.g' |sed 's.\\.-.g' |sed 's/\[//g' |sed 's/\]//g' |sed 's/  */ /g' |sed 's/%//g' |grep -v StackName |grep -v StackId |grep -v PhysicalResourceId > CF_EVENTS.txt
# 
# EVENTS=$(cat CF_EVENTS.txt |grep -v ResourceProperties)
# 
# echo "$EVENTS" > CF_EVENTS.txt
# 
# cat CF_EVENTS.txt
# 
# CF_EVENTS=$(cat CF_EVENTS.txt)
# 
# curl -X POST -H 'Content-type: application/json' --data '{"cloudformation_summary": "'"${OUTPUT}"'", "cloudformation_events": "'"${CF_EVENTS}"'"}' $SLACK_URL
