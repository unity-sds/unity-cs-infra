#!/bin/sh
export STACK_NAME="unity-cs-nightly-management-console"

## Retrieve the github token from SSM
export SSM_GITHUB_TOKEN="/unity-sds/u-cs/nightly/githubtoken"
GITHUB_TOKEN=$(aws ssm get-parameter          --name ${SSM_GITHUB_TOKEN}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
if [ -z "$GITHUB_TOKEN" ] 
then 
    echo "ERROR: Could not read Github Token from SSM.  Does the key [$SSM_GITHUB_TOKEN] exist?"
    exit
fi


rm -f nightly_output.txt
rm -f cloudformation_events.txt
rm -f results.xml


NIGHTLY_HASH=$(git rev-parse --short HEAD)
echo "Using nightly test repo commit [$NIGHTLY_HASH]" >> nightly_output.txt

## update self
git pull origin main

## update cloudformation scripts
rm -rf cloudformation
git clone https://oauth2:$GITHUB_TOKEN@github.com/unity-sds/cfn-ps-jpl-unity-sds.git cloudformation
cd cloudformation
CLOUDFORMATION_HASH=$(git rev-parse --short HEAD)
cd ..
echo "Using cfn-ps-jpl-unity-sds repo commit [$CLOUDFORMATION_HASH]" >> nightly_output.txt
cp ./cloudformation/templates/unity-mc.main.template.yaml template.yml

# Prepare xml test results
## Start outputting to reslts file
TEST_START_TIME=$(date +%s)
TEST_ERRORS=0
TEST_FAILURES=0
TEST_SKIPPED=0
TEST_TOTAL=0
TEST_HOSTNAME=$(hostname)
TEST_TIMESTAMP=$(date +%s)
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > results.xml
echo "<testsuites>" >> results.xml
echo "	<testsuite name=\"U-CS Nightly Deployment Test\" errors=\"{TEST_ERRORS}\" failures=\"{TEST_FAILURES}\" skipped=\"{TEST_SKIPPED}\" tests=\"{TEST_TOTAL}\" time=\"{TEST_TIME}\" timestamp=\"${TEST_TIMESTAMP}\" hostname=\"${TEST_HOSTNAME}\">" >> results.xml



#bash deploy.sh
#bash step2.sh &

TEST_TOTAL=$((TEST_TOTAL+1))
echo "		<testcase classname="nightly_deployment" name="test_adding_pass_case" time="0.001" />" >> results.xml


TEST_TOTAL=$((TEST_TOTAL+1))
TEST_ERRORS=$((TEST_ERRORS+1))
echo "		<testcase classname=\"nightly_deployment\" name=\"test_adding_error_case\" time=\"0.001\" >" >> results.xml
echo "			<error message=\"error message\">error log</error>" >> results.xml
echo "		</testcase>" >> results.xml

TEST_TOTAL=$((TEST_TOTAL+1))
TEST_FAILURES=$((TEST_FAILURES+1))
echo "		<testcase classname=\"nightly_deployment\" name=\"test_adding_failure_case\" time=\"0.001\" >" >> results.xml
echo "			<failure message=\"failure message\">failure log</failure>" >> results.xml
echo "		</testcase>" >> results.xml

TEST_TOTAL=$((TEST_TOTAL+1))
TEST_SKIPPED=$((TEST_SKIPPED+1))
echo "		<testcase classname=\"nightly_deployment\" name=\"test_adding_skipped_case\" time=\"0.001\" >" >> results.xml
echo "			<skipped message=\"skipped message\">skipped log</skipped>" >> results.xml
echo "		</testcase>" >> results.xml

# aws cloudformation describe-stack-events --stack-name ${STACK_NAME} >> cloudformation_events.txt


# sleep 10
#bash destroy.sh


# Add tests to results file
TEST_END_TIME=$(date +%s)
TEST_TIME=$((TEST_END_TIME-TEST_START_TIME))

echo "	</testsuite>" >> results.xml
echo "</testsuites>" >> results.xml

sed -i 's/{TEST_ERRORS}/'${TEST_ERRORS}'/g' results.xml
sed -i 's/{TEST_SKIPPED}/'${TEST_SKIPPED}'/g' results.xml
sed -i 's/{TEST_FAILURES}/'${TEST_FAILURES}'/g' results.xml
sed -i 's/{TEST_TOTAL}/'${TEST_TOTAL}'/g' results.xml
sed -i 's/{TEST_TIME}/'${TEST_TIME}'/g' results.xml


#cat nightly_output.txt

OUTPUT=$(cat nightly_output.txt)

WEBHOOK_URL="https://hooks.slack.com/workflows/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"

cat cloudformation_events.txt |sed 's/\s*},*//g' |sed 's/\s*{//g' |sed 's/\s*\]//' |sed 's/\\"//g' |sed 's/"//g' |sed 's/\\n//g' |sed 's/\\/-/g' |sed 's./.-.g' |sed 's.\\.-.g' |sed 's/\[//g' |sed 's/\]//g' |sed 's/  */ /g' |sed 's/%//g' |grep -v StackName |grep -v StackId |grep -v PhysicalResourceId > CF_EVENTS.txt

EVENTS=$(cat CF_EVENTS.txt |grep -v ResourceProperties)

echo "$EVENTS" > CF_EVENTS.txt

cat CF_EVENTS.txt

CF_EVENTS=$(cat CF_EVENTS.txt)

#curl -X POST -H 'Content-type: application/json' --data '{"cloudformation_summary": "'"${OUTPUT}"'", "cloudformation_events": "'"${CF_EVENTS}"'"}' $WEBHOOK_URL