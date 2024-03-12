#!/bin/bash

DESTROY=""
RUN_TESTS=""
PROJECT_NAME=""
VENUE_NAME=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 --destroy <true|false> --run-tests <true|false> --project-name <PROJECT_NAME> --venue-name <VENUE_NAME>"
    exit 1
}

#
# It's mandatory to speciy a valid number of command arguments
#
if [[ $# -ne 8 ]]; then
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
        --run-tests)
            case "$2" in
                true)
                    RUN_TESTS=true
                    ;;
                false)
                    RUN_TESTS=false
                    ;;
                *)
                    echo "Invalid argument for --run-tests. Please specify 'true' or 'false'." >&2
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --venue-name)
            VENUE_NAME="$2"
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
if [[ -z $RUN_TESTS ]]; then
    usage
fi
if [[ -z $PROJECT_NAME ]]; then
    usage
fi
if [[ -z $VENUE_NAME ]]; then
    usage
fi
# Install python3-pip
sudo apt update
sudo apt install -y python3-pip

# Install packages required for selenium tests
#
# Install pytest if not installed
pip3 list | grep pytest > out.txt
if ! grep -q pytest out.txt; then
    echo "Installing pytest..."
    pip3 install pytest
fi

# Install boto3 if not installed
pip3 list | grep boto3 > out.txt
if ! grep -q boto3 out.txt; then
    echo "Installing boto3..."
    pip3 install boto3
fi

# Install selenium if not installed
pip3 list | grep selenium > out.txt
if ! grep -q selenium out.txt; then
    echo "Installing selenium..."
    pip3 install selenium
fi

rm out.txt

echo "RUN ARGUMENTS: "
echo "  - Destroy stack at end of script? $DESTROY"
echo "  - Run tests?                      $RUN_TESTS"
echo "  - Project Name:                   $PROJECT_NAME"
echo "  - Venue Name:                     $VENUE_NAME"
echo "---------------------------------------------------------"

export STACK_NAME="unity-management-console-${PROJECT_NAME}-${VENUE_NAME}"
export GH_BRANCH=main
export GH_CF_BRANCH=main
TODAYS_DATE=$(date '+%F_%H-%M')
LOG_DIR=nightly_logs/log_${TODAYS_DATE}

#
# Create common SSM params
#
source ./set_common_ssm_params.sh

#
# Check values are set
#
if [ -z "$GITHUB_TOKEN_VAL" ] ; then
    echo "ERROR: Could not read Github Token from SSM." ; exit 1
fi
if [ -z "$SLACK_URL_VAL" ] ; then 
    echo "ERROR: Could not read Slack URL from SSM." ; exit 1
fi
if [ -z "$GITHUB_USERNAME_VAL" ] ; then 
    echo "ERROR: Could not read Github username from SSM." ; exit 1
fi
if [ -z "$GITHUB_USEREMAIL_VAL" ] ; then 
    echo "ERROR: Could not read Github user email from SSM." ; exit 1
fi

#
# Make sure git is properly setup
#
git config --global user.email ${GITHUB_USEREMAIL_VAL}
git config --global user.name ${GITHUB_USERNAME_VAL}
git remote set-url origin https://oauth2:${GITHUB_TOKEN_VAL}@github.com/unity-sds/unity-cs-infra.git

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
git clone https://oauth2:$GITHUB_TOKEN_VAL@github.com/unity-sds/cfn-ps-jpl-unity-sds.git cloudformation
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
bash deploy.sh --stack-name "${STACK_NAME}" --project-name "${PROJECT_NAME}" --venue-name "${VENUE_NAME}"

echo "Sleeping for 360s to give enough time for stack to fully come up..."
sleep 360  # give enough time for stack to fully come up. TODO: revisit this approach

aws cloudformation describe-stack-events --stack-name ${STACK_NAME} >> cloudformation_events.txt

# Get MC URL from SSM (Manamgement Console populates this value)
export SSM_MC_URL="/unity/cs/management/httpd/loadbalancer-url"
export MANAGEMENT_CONSOLE_URL=$(aws ssm get-parameter --name ${SSM_MC_URL}  |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
echo "MANAGEMENT_CONSOLE_URL = ${MANAGEMENT_CONSOLE_URL}"

if [[ "$RUN_TESTS" == "true" ]]; then
  echo "Checking if Docker is installed..."
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
else
  echo "Not checking if docker is installed (--run-tests false)."
fi # END IF RUN-TESTS

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
        break
    else
        echo "Attempt $attempt to reach Management Console via httpd -- Received HTTP response code $response_code. Retrying in $interval seconds..."
        sleep $interval
        ((attempt++))
    fi
done

# Cloud formation smoke_test
echo "Running Smoke Test"
python3 smoke_test.py >>  nightly_output.txt 2>&1

# Save the exit status of the Python script
SMOKE_TEST_STATUS=$?

if [ $SMOKE_TEST_STATUS -eq 0 ]; then
    echo "Smoke test was successful. Continuing with bootstrap and tests."
    echo "Smoke test was successful. Continuing with bootstrap and tests." >> nightly_output.txt
    
    if [[ "$RUN_TESTS" == "true" ]]; then
      # Place the rest of your script here that should only run if smoke_test.py succeeds
      echo "Running Selenium tests..."
      pytest test_selenium_mc.py -v --tb=short >> selenium_nightly_output.txt 2>&1
      
      # Concatenate makereport_output.txt to nightly_output.txt
      cat makereport_output.txt >> nightly_output.txt
      
      # Cleanup and log management
      echo "Stopping Selenium docker container..."
      sudo docker stop $CONTAINER_ID

      cp selenium_nightly_output.txt "nightly_output_$TODAYS_DATE.txt"
      mv nightly_output_$TODAYS_DATE.txt ${LOG_DIR}
      mv selenium_unity_images/* ${LOG_DIR}
      
      #Delete logs older then 2 weeks
      bash delete_old_logs.sh
      
      # Push the output logs/screenshots to Github for auditing purposes
      echo "Pushing test results to ${LOG_DIR}..."
      git add nightly_tests/nightly_logs
      git add "${LOG_DIR}/nightly_output_$TODAYS_DATE.txt"
      git add ${LOG_DIR}/*
      git commit -m "Add nightly output for $TODAYS_DATE"
      git pull origin ${GH_BRANCH}
      git checkout ${GH_BRANCH}
      git push origin ${GH_BRANCH}
    else
      echo "Not running Selenium tests. (--run-tests false)"
    fi
else
    echo "Smoke test failed or could not be verified. Skipping tests."
    echo "Smoke test failed or could not be verified. Skipping tests." >> nightly_output.txt
fi

# Decide on resource destruction based on the smoke test result or DESTROY flag
if [[ "$DESTROY" == "true" ]] || [ $SMOKE_TEST_STATUS -ne 0 ]; then
  echo "Destroying resources..."
  bash destroy.sh --project-name "${PROJECT_NAME}" --venue-name "${VENUE_NAME}"
else
  echo "Not destroying resources. Smoke tests were successful and no destruction requested."
fi

#
# Parse and print out CloudFormation events
#
cat cloudformation_events.txt |sed 's/\s*},*//g' |sed 's/\s*{//g' |sed 's/\s*\]//' |sed 's/\\"//g' |sed 's/"//g' |sed 's/\\n//g' |sed 's/\\/-/g' |sed 's./.-.g' |sed 's.\\.-.g' |sed 's/\[//g' |sed 's/\]//g' |sed 's/  */ /g' |sed 's/%//g' |grep -v StackName |grep -v StackId |grep -v PhysicalResourceId > CF_EVENTS.txt
EVENTS=$(cat CF_EVENTS.txt |grep -v ResourceProperties)
echo "$EVENTS" > CF_EVENTS.txt
cat CF_EVENTS.txt
CF_EVENTS=$(cat CF_EVENTS.txt)

# The rest of your script, including posting to Slack, can go here
# Ensure to only post to Slack if tests were run successfully
if [[ "$RUN_TESTS" == "true" ]] && [ $SMOKE_TEST_STATUS -eq 0 ]; then

  OUTPUT=$(cat nightly_output.txt)
  GITHUB_LOGS_URL="https://github.com/unity-sds/unity-cs-infra/tree/${GH_BRANCH}/nightly_tests/${LOG_DIR}"
  
  # Post results to Slack
  curl -X POST -H 'Content-type: application/json' \
  --data '{"cloudformation_summary": "'"${OUTPUT}"'", "cloudformation_events": "'"${CF_EVENTS}"'", "logs_url": "'"${GITHUB_LOGS_URL}"'"}' \
  ${SLACK_URL}
else
    echo "Not posting results to slack (--run-tests)"
fi

