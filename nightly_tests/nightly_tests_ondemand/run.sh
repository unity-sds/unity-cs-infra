#!/bin/sh
export STACK_NAME="unity-cs-nightly-management-console"
TODAYS_DATE=$(date +%F)
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
echo "Repo Hash (Nightly Test):     [$NIGHTLY_HASH]" >> nightly_output.txt
echo "Repo Hash (Nightly Test):     [$NIGHTLY_HASH]"

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
echo "Repo Hash (Cloudformation):   [$CLOUDFORMATION_HASH]" >> nightly_output.txt
echo "Repo Hash (Cloudformation):   [$CLOUDFORMATION_HASH]"

cp ./cloudformation/templates/unity-mc.main.template.yaml template.yml


bash deploy.sh
#bash step2.sh &

aws cloudformation describe-stack-events --stack-name ${STACK_NAME} >> cloudformation_events.txt

# run selenium test on management console
export MANAGEMENT_CONSOLE_URL=$(aws cloudformation describe-stacks --stack-name unity-cs-nightly-management-console --query "Stacks[0].Outputs[?OutputKey=='ManagementConsoleURL'].OutputValue" --output text)

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

python3 selenium_test_management_console.py >> nightly_output.txt
sudo docker stop $CONTAINER_ID

mv nightly_output.txt "nightly_output_$TODAYS_DATE.txt"

git config --global user.email "smolensk@jpl.nasa.gov"
git config --global user.name "jonathansmolenski "
git add "nightly_output_$TODAYS_DATE.txt"
git add /selenium_unity_images/*
git commit -m "Add nightly output for $TODAYS_DATE"
git remote set-url origin https://oauth2:${GITHUB_TOKEN}@github.com/unity-sds/unity-cs-infra.git
git push origin main


sleep 10
bash destroy.sh

#cat nightly_output.txt

OUTPUT=$(cat nightly_output.txt)


cat cloudformation_events.txt |sed 's/\s*},*//g' |sed 's/\s*{//g' |sed 's/\s*\]//' |sed 's/\\"//g' |sed 's/"//g' |sed 's/\\n//g' |sed 's/\\/-/g' |sed 's./.-.g' |sed 's.\\.-.g' |sed 's/\[//g' |sed 's/\]//g' |sed 's/  */ /g' |sed 's/%//g' |grep -v StackName |grep -v StackId |grep -v PhysicalResourceId > CF_EVENTS.txt
 
EVENTS=$(cat CF_EVENTS.txt |grep -v ResourceProperties)

echo "$EVENTS" > CF_EVENTS.txt

cat CF_EVENTS.txt

CF_EVENTS=$(cat CF_EVENTS.txt)

curl -X POST -H 'Content-type: application/json' --data '{"cloudformation_summary": "'"${OUTPUT}"'", "cloudformation_events": "'"${CF_EVENTS}"'"}' $SLACK_URL
