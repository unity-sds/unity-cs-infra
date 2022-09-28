# Terraform to Deploy Unity API Gateway

This Document is a Work in Progress

## Prerequisites
- Terraform
- AWS CLI

## Steps to Deploy the API Gateway

1. Open a terminal and set the following environment variables with correct values associated with your AWS account.

```shell
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
export AWS_DEFAULT_REGION=us-west-2
```

2. The following parameters should be available in the AWS System Manager (SSM) Parameter Store before deploying the API Gateway. These values can be set
as a result of a previous deployment (E.g.: A lambda function deployment) or can be set using AWS Console or AWS CLI.

```shell
/unity/dev/unity-sps-1/api-gateway/functions/cs-lambda-authorizer-uri
/unity/dev/unity-sps-1/api-gateway/integrations/uads-dockstore-nlb-uri
/unity/dev/unity-sps-1/api-gateway/integrations/uads-dev-dockstore-link-2-vpc-link-id
/unity/dev/unity-sps-1/api-gateway/integrations/uds-dev-cumulus-cumulus_granules_dapa-function-uri
/unity/dev/unity-sps-1/api-gateway/integrations/uds-dev-cumulus-cumulus_collections_dapa-function-uri
```

If these parameters are not available, it is possible to set these parameters using the AWS CLI as follows.

Tips:

#### A function URI for a lambda function can be derived as follows.

Example:
    The `arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:1234567890:function:cs-lambda-authorizer/invocations`

Can be derived with:
    
     "arn:aws:apigateway:" + <AWS_REGION_OF_FUNCTION> + ":lambda:path/2015-03-31/functions/" + <ARN_OF_THE_FUNCTION> + "/invocations"


#### Example 

In this example, the account number is purposefully set to 1234567890 and also added fake values. Please replace these values with correct values): 
```shell

aws ssm put-parameter --name "/unity/dev/unity-sps-1/api-gateway/functions/cs-lambda-authorizer-uri" \
    --value "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:1234567890:function:cs-lambda-authorizer/invocations" \
    --type String
    
aws ssm put-parameter --name "/unity/dev/unity-sps-1/api-gateway/integrations/uads-dockstore-nlb-uri" \
    --value "http://uads-dockstore-nlb.elb.us-west-2.amazonaws.com:9999/{proxy}" \
    --type String
    
aws ssm put-parameter --name "/unity/dev/unity-sps-1/api-gateway/integrations/uads-dev-dockstore-link-2-vpc-link-id" \
    --value "abcde" \
    --type String

aws ssm put-parameter --name "/unity/dev/unity-sps-1/api-gateway/integrations/uds-dev-cumulus-cumulus_granules_dapa-function-uri" \
    --value "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:1234567890:function:uds-dev-cumulus-cumulus_granules_dapa/invocations" \
    --type String
    
aws ssm put-parameter --name "/unity/dev/unity-sps-1/api-gateway/integrations/uds-dev-cumulus-cumulus_collections_dapa-function-uri" \
    --value "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:1234567890:function:uds-dev-cumulus-cumulus_collections_dapa/invocations" \
    --type String
    
```

3. Clone unity-cs repository (api-gateway-terraform branch)
```shell
git clone https://github.com/unity-sds/unity-cs.git -b api-gateway-terraform
```

4. Change current working directory to `terraform/terraform-api-gateway`

```shell
cd unity-cs/terraform/terraform-api-gateway/
```

5. Check the YAML file at `unity-cs/terraform/terraform-api-gateway/terraform-modules/unity-rest-api-gateway-oas30.yaml`,
which contains the Open API Specification 3.0 definition of Unity API Gateway and make necessary updates (only if required). You can use 
this file to define a complete API Gateway by adding, updating, deleting API resources and methods, configuring authorizers and
setting-up integration points.

7. Execute following commands to deploy the API Gateway.

```shell
terraform init
```

```shell
terraform apply
```

7. Visit the API Gateway service and observe the newly deployed API Gateway (in this example, it takes the name "Unity CS Experimental REST API Gateway").

8. To delete the API Gateway, you may use the following command.

```shell
terraform destroy
```
