This readme has information pertaining to the various workflows.  These can be invoked either directly from the GitHub Actions web page, or via [`act`](https://github.com/nektos/act) on the Unity Control Plane EC2 server inside AWS.

## General Flow of the Prototype
The general idea, in the short-term, is to support the deployment of the SPS service area, by chaining together an EKS deployment, then a SPS software stack.  The below workflows support this use case.  

## Workflows:
### ```development-action-not-for-long-term-use-only-use-if-you-know-what-you-are-doing```
This workflow uses a metadata-driven approach to run the [unity-cs-action plugin](https://github.com/unity-sds/unity-cs-action/blob/main/src/main.ts) which interprets the metadata, and deals with the chaining of child workflows.
 * ```deploy_eks``` (see below)
 * ```software_deployment``` (see below)

#### To Test:
 1)  Click Run workflow
 2) Modify the `clustername` variable to be something unique (e.g. your name)
 3) Click Go
 NOTE:  by default, this will deploy to the MCP DEV AWS account
 4) Go to the MCP DEV account (via Kion) and view what is deploying

### ```deploy_eks```
This workflow deploys EKS into the various environments.

### ```software_deployment``` (formerly known as "Deploy OIDC")
This workflow supports deployment of the various Unity service areas into multiple environments.

### ```deployment_api_gateway_and_cognito```
documentation coming soon...

### ```deployment_destroy_api_gateway_and_cognito```
documentation coming soon...

### ```docker-publish```
documentation coming soon...

### ```nightly```
documentation coming soon...


# TESTING

