#!/bin/bash

export STACK_NAME="unity-cs-nightly-management-console"
export GH_BRANCH=main
export GH_CF_BRANCH=main
TODAYS_DATE=$(date '+%F_%H-%M')
LOG_DIR=nightly_logs/log_${TODAYS_DATE}

## Retrieve the github token from SSM
export SSM_GITHUB_TOKEN="/unity/testing/nightly/githubtoken" # TODO: switch this value out in SSM
export SSM_SLACK_URL="/unity/ci/slack-web-hook-url"

export SLACK_URL=$(aws ssm get-parameter    --name ${SSM_SLACK_URL}    |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
export GITHUB_TOKEN=$(aws ssm get-parameter --name ${SSM_GITHUB_TOKEN} |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')

if [ -z "$GITHUB_TOKEN" ] 
then 
    echo "ERROR: Could not read Github Token from SSM.  Does the key [$SSM_GITHUB_TOKEN] exist?"
    exit
fi
if [ -z "$SLACK_URL" ] 
then 
    echo "ERROR: Could not read Slack URL from SSM.  Does the key [$SSM_SLACK_URL] exist?"
    exit
fi


rm -f nightly_output.txt
rm -f cloudformation_events.txt
mkdir -p nightly_logs/log_$TODAYS_DATE

NIGHTLY_HASH=$(git rev-parse --short HEAD)
#echo "Using nightly test repo commit [$NIGHTLY_HASH]" >> nightly_output.txt
#echo"--------------------------------------------------------------------------[PASS]"
echo "Repo Hash (Nightly Test):     [$NIGHTLY_HASH]" >> nightly_output.txt
echo "Repo Hash (Nightly Test):     [$NIGHTLY_HASH]"

## update self
git pull origin ${GH_BRANCH}

## update cloudformation scripts
rm -rf cloudformation
git clone https://oauth2:$GITHUB_TOKEN@github.com/unity-sds/cfn-ps-jpl-unity-sds.git cloudformation
cd cloudformation

## This is for testing a specific branch of the cloudformation repo
git checkout ${GH_CF_BRANCH}
git pull origin ${GH_CF_BRANCH}

CLOUDFORMATION_HASH=$(git rev-parse --short HEAD)
cd ..
#echo "Using cfn-ps-jpl-unity-sds repo commit [$CLOUDFORMATION_HASH]" >> nightly_output.txt
#echo"--------------------------------------------------------------------------[PASS]"
echo "Repo Hash (Cloudformation):   [$CLOUDFORMATION_HASH]" >> nightly_output.txt
echo "Repo Hash (Cloudformation):   [$CLOUDFORMATION_HASH]"

cp ./cloudformation/templates/unity-mc.main.template.yaml template.yml

#
# Deploy the Management Console using CloudFormation
#
bash deploy.sh
#bash step2.sh &

sleep 360  # give enough time for stack to full come up. TODO: revisit this approach

aws cloudformation describe-stack-events --stack-name ${STACK_NAME} >> cloudformation_events.txt

# Get MC URL
export SSM_MC_URL="/unity/cs/management/httpd/loadbalancer-url"
export MANAGEMENT_CONSOLE_URL=$(aws ssm get-parameter --name ${SSM_MC_URL}  |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')

# run selenium test on management console
# export MANAGEMENT_CONSOLE_URL=$(aws cloudformation describe-stacks --stack-name unity-cs-nightly-management-console --query "Stacks[0].Outputs[?OutputKey=='ManagementConsoleURL'].OutputValue" --output text)

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not installed. Installing Docker..."

    # Add Docker's official GPG key
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl start docker
    sleep 10

    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

sudo docker pull selenium/standalone-chrome
CONTAINER_ID=$(sudo docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-chrome)
sleep 10

cp nightly_output.txt selenium_nightly_output.txt

#
# Run the Selenium test suite against the running Management Console
#
pytest test_selenium_mc.py -v --tb=short >> selenium_nightly_output.txt 2>&1
# TODO: revisit makereport naming
cat makereport_output.txt >> nightly_output.txt

# we are done testing, so don't need the selenium docker anymore
sudo docker stop $CONTAINER_ID

cp selenium_nightly_output.txt "nightly_output_$TODAYS_DATE.txt"
mv nightly_output_$TODAYS_DATE.txt ${LOG_DIR}
mv selenium_unity_images/* ${LOG_DIR}

#
# Push the output logs/screenshots to Github for auditing purposes
#
# TODO: revisit these below two values
git config --global user.email "smolensk@jpl.nasa.gov" # CHANGE TO SSM param
git config --global user.name "jonathansmolenski"      # CHANGE TO SSM param 
git add "${LOG_DIR}/nightly_output_$TODAYS_DATE.txt"
git add ${LOG_DIR}/*
git commit -m "Add nightly output for $TODAYS_DATE"
git remote set-url origin https://oauth2:${GITHUB_TOKEN}@github.com/unity-sds/unity-cs-infra.git
git push origin ${GH_BRANCH}

#
# Destroy resources as testing is now complete
#
sleep 10 
bash destroy.sh

OUTPUT=$(cat nightly_output.txt)
GITHUB_LOGS_URL="https://github.com/unity-sds/unity-cs-infra/tree/${GH_BRANCH}/nightly_tests/nightly_tests_ondemand/${LOG_DIR}"


cat cloudformation_events.txt |sed 's/\s*},*//g' |sed 's/\s*{//g' |sed 's/\s*\]//' |sed 's/\\"//g' |sed 's/"//g' |sed 's/\\n//g' |sed 's/\\/-/g' |sed 's./.-.g' |sed 's.\\.-.g' |sed 's/\[//g' |sed 's/\]//g' |sed 's/  */ /g' |sed 's/%//g' |grep -v StackName |grep -v StackId |grep -v PhysicalResourceId > CF_EVENTS.txt
 
EVENTS=$(cat CF_EVENTS.txt |grep -v ResourceProperties)

echo "$EVENTS" > CF_EVENTS.txt

cat CF_EVENTS.txt

CF_EVENTS=$(cat CF_EVENTS.txt)

#
# Post results to Slack
#
# curl -X POST -H 'Content-type: application/json' --data '{"cloudformation_summary": "'"${OUTPUT}"'", "cloudformation_events": "'"${CF_EVENTS}"'"}' $SLACK_URL
curl -X POST -H 'Content-type: application/json' \
--data '{"cloudformation_summary": "'"${OUTPUT}"'", "cloudformation_events": "'"${CF_EVENTS}"'", "logs_url": "'"${GITHUB_LOGS_URL}"'"}' \
${SLACK_URL}

