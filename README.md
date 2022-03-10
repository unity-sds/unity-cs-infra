# unity-cs-infra

Framework code which allows for configuration of an AWS environment necessary to do the things that U-CS needs to :
 * build (perhaps not for all service areas -- but offered if they want it)
 * unit test
 * publish
 * integration tests. (run U-CS end)
 * deploy (U-CS)
 * etc..

This repo also houses the GitHub actions (push-button for now) that can trigger builds, tests, etc..


## What is Unity CS?

Unity CS is a framework of common components for the Unity project.  These components include (but are not limited to):
* Software deployment workflows
* Smoke Test workflows
* Environment teardown workflows
* Software build workflows

The goal of Unity CS is to remove much of the hassle of build and deploy work 
from developers and implement it in an automated manner that is both 
transparent and executes seamlessly.

## What does Unity Leverage to complete it's goals?
tools
standardized file locations

How to prepare a repository for use in Unity
In order to prepare a repository for automated builds and deployments certain 
standardized paths and filenames must be utilized so that Unity knows where 
to find them.

### Automated Builds
TBD

### Unit Testing
TBD

### Automated Deployments
Deployments are handled through Terraform.  Terraform scripts are stored in the 
terraform-unity directory in a repositorys root directory.  At deployment time 
the terraform scripts are validated and 

```
.
└── terraform-unity
    ├── main.tf
    ├── networking.tf
    └── variables.tf
```


### Smoke Testing
Smoke tests are a simple test to validate a successful deployment.  While they 
may not test all the functionality of a system, they should be comprehensive 
enough to fail if the deployment has failed.

In order for Unity to find the smoke tests, they must live in the smoketest 
directory.  Currently python smoktetests are supported, but additional formats 
will be supported in the future.
```
.
└── smoketest
    └── smoketest.py
```

### Teardown
Teardowns are managed in the same way as deployments, through Terraform.  The
teardown workflow is supplied by Unity and requires no additional files in the 
target repository as long as the terraform-unity directory is set up correctly.