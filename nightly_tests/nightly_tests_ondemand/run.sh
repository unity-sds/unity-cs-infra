#!/bin/bash

DESTROY=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 --destroy <true|false>"
    exit 1
}

#
# It's mandatory to speciy a valid --destroy command argument
#
if [[ $# -ne 2 ]]; then
  usage
fi

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --destroy)
            case "$2" in
                true)
                    DESTROY=true
                    ;;
                false)
                    DESTROY=false
                    ;;
                *)
                    echo "Invalid argument for --destroy. Please specify 'true' or 'false'." >&2
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        *)
            echo "Invalid option: $1" >&2
            exit 1
            ;;
    esac
done

# Check if mandatory options are provided
if [[ -z $DESTROY ]]; then
    usage
fi

echo "Destroy stack at end of script?: $DESTROY"

export STACK_NAME="unity-cs-nightly-management-console"
export GH_BRANCH=main
export GH_CF_BRANCH=main
TODAYS_DATE=$(date '+%F_%H-%M')
LOG_DIR=nightly_logs/log_${TODAYS_DATE}

#
# SSM Parameters
#
export SSM_GITHUB_TOKEN="/unity/ci/github/token"
export SSM_SLACK_URL="/unity/ci/slack-web-hook-url"
export SSM_GITHUB_USERNAME="/unity/ci/github/username"
export SSM_GITHUB_USEREMAIL="/unity/ci/github/useremail"

export SLACK_URL=$(aws ssm get-parameter    --name ${SSM_SLACK_URL}    |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
export GITHUB_TOKEN=$(aws ssm get-parameter --name ${SSM_GITHUB_TOKEN} |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
export GITHUB_USERNAME=$(aws ssm get-parameter --name ${SSM_GITHUB_USERNAME} |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
export GITHUB_USEREMAIL=$(aws ssm get-parameter --name ${SSM_GITHUB_USEREMAIL} |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')

if [ -z "$GITHUB_TOKEN" ] ; then
    echo "ERROR: Could not read Github Token from SSM.  Does the key [$SSM_GITHUB_TOKEN] exist?" ; exit 1
fi
if [ -z "$SLACK_URL" ] ; then 
    echo "ERROR: Could not read Slack URL from SSM.  Does the key [$SSM_SLACK_URL] exist?" ; exit 1
fi
if [ -z "$GITHUB_USERNAME" ] ; then 
    echo "ERROR: Could not read Github username from SSM.  Does the key [$SSM_GITHUB_USERNAME] exist?" ; exit 1
fi
if [ -z "$GITHUB_USEREMAIL" ] ; then 
    echo "ERROR: Could not read Github user email from SSM.  Does the key [$SSM_GITHUB_USEREMAIL] exist?" ; exit 1
fi

#
# Make sure git is properly setup
#
git config --global user.email ${GITHUB_USEREMAIL}
git config --global user.name ${GITHUB_USERNAME}
git remote set-url origin https://oauth2:${GITHUB_TOKEN}@github.com/unity-sds/unity-cs-infra.git

rm -f nightly_output.txt
rm -f cloudformation_events.txt
mkdir -p ${LOG_DIR}

NIGHTLY_HASH=$(git rev-parse --short HEAD)
echo "Repo Hash (Nightly Test):     [$NIGHTLY_HASH]" >> nightly_output.txt
echo "Repo Hash (Nightly Test):     [$NIGHTLY_HASH]"

## update self (unity-cs-infra repository)
git pull origin ${GH_BRANCH}
git checkout ${GH_BRANCH}

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

echo "Sleeping for 500s to give enough time for stack to fully come up..."
sleep 360  # give enough time for stack to fully come up. TODO: revisit this approach

aws cloudformation describe-stack-events --stack-name ${STACK_NAME} >> cloudformation_events.txt

# Get MC URL from SSM (Manamgement Console populates this value)
export SSM_MC_URL="/unity/cs/management/httpd/loadbalancer-url"
export MANAGEMENT_CONSOLE_URL=$(aws ssm get-parameter --name ${SSM_MC_URL}  |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
echo "MANAGEMENT_CONSOLE_URL = ${MANAGEMENT_CONSOLE_URL}"

#
# Check if Docker is installed
#
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
    echo "Docker already installed [OK]"
fi

sudo docker pull selenium/standalone-chrome
echo "Launching selenium docker..."
CONTAINER_ID=$(sudo docker run -d -p 4444:4444 -v /dev/shm:/dev/shm selenium/standalone-chrome)
sleep 10

cp nightly_output.txt selenium_nightly_output.txt

#
# Wait until a succesful HTTP code is being returned
# from the load balancer, indicating the Management Console is accessible
#
interval=10  # polling interval in seconds
max_attempts=50
attempt=1
while [ $attempt -le $max_attempts ]; do
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$MANAGEMENT_CONSOLE_URL")
    if [[ $response_code =~ ^[2-3][0-9]{2}$ ]]; then
        echo "Success! HTTP response code $response_code received."
        exit 0
    else
        echo "Attempt $attempt: Received HTTP response code $response_code. Retrying in $interval seconds..."
        sleep $interval
        ((attempt++))
    fi
done


#
# Run the Selenium test suite against the running Management Console
#
pytest test_selenium_mc.py -v --tb=short >> selenium_nightly_output.txt 2>&1
# TODO: revisit makereport naming
cat makereport_output.txt >> nightly_output.txt

# we are done testing, so don't need the selenium docker anymore
echo "Stopping Selenium docker container..."
sudo docker stop $CONTAINER_ID

cp selenium_nightly_output.txt "nightly_output_$TODAYS_DATE.txt"
mv nightly_output_$TODAYS_DATE.txt ${LOG_DIR}
mv selenium_unity_images/* ${LOG_DIR}

#
# Push the output logs/screenshots to Github for auditing purposes
#
echo "Pushing test results to ${LOG_DIR}..."
git add "${LOG_DIR}/nightly_output_$TODAYS_DATE.txt"
git add ${LOG_DIR}/*
git commit -m "Add nightly output for $TODAYS_DATE"
git pull origin ${GH_BRANCH}
git checkout ${GH_BRANCH}
git push origin ${GH_BRANCH}

#
# Destroy resources as testing is now complete
#
sleep 10 
if [[ "$DESTROY" == "true" ]]; then
  echo "Destroying resources..."
  bash destroy.sh
else
  echo "Not destroying resources..."
fi

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

