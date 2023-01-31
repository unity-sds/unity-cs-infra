This readme has information pertaining to the various workflows.

## General Flow of the Prototype
The general idea, in the short-term, is to support the deployment of the SPS service area, by chaining together an EKS deployment, then a SPS software stack.  The below workflows support this use case.  

## Workflows:
### test_action
This workflow uses a metadata-driven approach to run the [unity-cs-action plugin](https://github.com/unity-sds/unity-cs-action/blob/main/src/main.ts) which interprets the metadata, and deals with the chaining of child workflows.

### deploy_eks
This workflow deploys EKS into the various environments.

### software_deployment (formerly known as "Deploy OIDC")
This workflow supports deployment of the various Unity service areas into multiple environments.

### deployment_api_gateway_and_cognito
documentation coming soon...

### deployment_destroy_api_gateway_and_cognito
documentation coming soon...

### docker-publish
documentation coming soon...
