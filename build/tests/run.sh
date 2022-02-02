#!/bin/bash

OUTPUT_FILE=report.xml
TEST_SUITE_STATUS=PASS


echo "<testsuites>" >$OUTPUT_FILE
echo "  <testsuite name=\"template\">" >>$OUTPUT_FILE
echo "    <testcase name=\"tests_were_run\">" >>$OUTPUT_FILE
echo "    </testcase>" >>$OUTPUT_FILE


TEST_DIR_NAME='tests'
echo "    <testcase name=\"${TEST_DIR_NAME}_dir_exists\">" >>$OUTPUT_FILE
if [ ! -d "../${TEST_DIR_NAME}" ]; then
  echo "      <failure message=\"${TEST_DIR_NAME} directory does not exist\">${TEST_DIR_NAME} directory does not exist</failure>" >>$OUTPUT_FILE
  TEST_SUITE_STATUS=FAIL
fi
echo "    </testcase>" >>$OUTPUT_FILE


TEST_DIR_NAME='terraform'
echo "    <testcase name=\"${TEST_DIR_NAME}_dir_exists\">" >>$OUTPUT_FILE
if [ ! -d "../${TEST_DIR_NAME}" ]; then
  echo "      <failure message=\"${TEST_DIR_NAME} directory does not exist\">${TEST_DIR_NAME} directory does not exist</failure>" >>$OUTPUT_FILE
  TEST_SUITE_STATUS=FAIL
fi
echo "    </testcase>" >>$OUTPUT_FILE


TEST_DIR_NAME='terraform/tfvars'
echo "    <testcase name=\"${TEST_DIR_NAME}_dir_exists\">" >>$OUTPUT_FILE
if [ ! -d "../${TEST_DIR_NAME}" ]; then
  echo "      <failure message=\"${TEST_DIR_NAME} directory does not exist\">${TEST_DIR_NAME} directory does not exist</failure>" >>$OUTPUT_FILE
  TEST_SUITE_STATUS=FAIL
fi
echo "    </testcase>" >>$OUTPUT_FILE



echo "  </testsuite>" >>$OUTPUT_FILE
echo "</testsuites>" >>$OUTPUT_FILE


if [ "$TEST_SUITE_STATUS" == "FAIL" ]; then
  exit 1
fi

exit

