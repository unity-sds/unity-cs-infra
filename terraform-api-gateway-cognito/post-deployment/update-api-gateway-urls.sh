#!/bin/bash

AWS_DEFAULT_REGION='us-west-2'
NAMESPACE='unity-sps'
COUNTER=3
STAGE='dev'
REST_API_ID='<ADD REST API ID>'

ADES_WPST_URL=$(aws ssm get-parameter --name "/unity/dev/${NAMESPACE}-${COUNTER}/api-gateway/stage-variables/ades-wpst-url" --query Parameter.Value --region "${AWS_DEFAULT_REGION}")
GRQ_ES_URL=$(aws ssm get-parameter --name "/unity/dev/${NAMESPACE}-${COUNTER}/api-gateway/stage-variables/grq-es-url" --query Parameter.Value --region "${AWS_DEFAULT_REGION}")
GRQ_REST_API_URL=$(aws ssm get-parameter --name "/unity/dev/${NAMESPACE}-${COUNTER}/api-gateway/stage-variables/grq-rest-api-url" --query Parameter.Value --region "${AWS_DEFAULT_REGION}")
HYSDS_UI_URL=$(aws ssm get-parameter --name "/unity/dev/${NAMESPACE}-${COUNTER}/api-gateway/stage-variables/hysds-ui-url" --query Parameter.Value --region "${AWS_DEFAULT_REGION}")
MOZART_ES_URL=$(aws ssm get-parameter --name "/unity/dev/${NAMESPACE}-${COUNTER}/api-gateway/stage-variables/mozart-es-url" --query Parameter.Value --region "${AWS_DEFAULT_REGION}")
MOZART_REST_API_URL=$(aws ssm get-parameter --name "/unity/dev/${NAMESPACE}-${COUNTER}/api-gateway/stage-variables/mozart-rest-api-url" --query Parameter.Value --region "${AWS_DEFAULT_REGION}")

aws apigateway update-stage --rest-api-id "${REST_API_ID}" --stage-name "${STAGE}" --region ${AWS_DEFAULT_REGION} --patch-operations op=replace,path=/variables/adesWpstUrl,value="${ADES_WPST_URL}"
aws apigateway update-stage --rest-api-id "${REST_API_ID}" --stage-name "${STAGE}" --region ${AWS_DEFAULT_REGION} --patch-operations op=replace,path=/variables/grqEsUrl,value="${GRQ_ES_URL}"
aws apigateway update-stage --rest-api-id "${REST_API_ID}" --stage-name "${STAGE}" --region ${AWS_DEFAULT_REGION} --patch-operations op=replace,path=/variables/grqRestApiUrl,value="${GRQ_REST_API_URL}"
aws apigateway update-stage --rest-api-id "${REST_API_ID}" --stage-name "${STAGE}" --region ${AWS_DEFAULT_REGION} --patch-operations op=replace,path=/variables/hysdsUiUrl,value="${HYSDS_UI_URL}"
aws apigateway update-stage --rest-api-id "${REST_API_ID}" --stage-name "${STAGE}" --region ${AWS_DEFAULT_REGION} --patch-operations op=replace,path=/variables/mozartEsUrl,value="${MOZART_ES_URL}"
aws apigateway update-stage --rest-api-id "${REST_API_ID}" --stage-name "${STAGE}" --region ${AWS_DEFAULT_REGION} --patch-operations op=replace,path=/variables/mozartRestApiUrl,value="${MOZART_REST_API_URL}"
