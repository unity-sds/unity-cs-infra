
<!-- Header block for project -->
<hr>

<div align="center">

![logo](https://user-images.githubusercontent.com/3129134/163255685-857aa780-880f-4c09-b08c-4b53bf4af54d.png)

<h1 align="center">Unity Common Services Infrastructure</h1>
<!-- ☝️ Replace with your repo name ☝️ -->

</div>

<pre align="center">Framework code which allows for configuration of an AWS environment necessary to do the things that U-CS needs</pre>
<!-- ☝️ Replace with a single sentence describing the purpose of your repo / proj ☝️ -->

<!-- Header block for project -->

[INSERT YOUR BADGES HERE (SEE: https://shields.io)] [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)
<!-- ☝️ Add badges via: https://shields.io e.g. ![](https://img.shields.io/github/your_chosen_action/your_org/your_repo) ☝️ -->

[INSERT SCREENSHOT OF YOUR SOFTWARE, IF APPLICABLE]
<!-- ☝️ Screenshot of your software (if applicable) via ![](https://uri-to-your-screenshot) ☝️ -->

[INSERT LIST OF IMPORTANT PROJECT / REPO LINKS HERE]
<!-- example links>
[Website](INSERT WEBSITE LINK HERE) | [Docs/Wiki](INSERT DOCS/WIKI SITE LINK HERE) | [Discussion Board](INSERT DISCUSSION BOARD LINK HERE) | [Issue Tracker](INSERT ISSUE TRACKER LINK HERE)
-->

## Introduction

### What is Unity CS?

<pre align="center">A framework for configuring AWS environments for Unity CS operations.</pre>

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md) [![SLIM](https://img.shields.io/badge/Best%20Practices%20from-SLIM-blue)](https://nasa-ammos.github.io/slim/)

### How does Unity CS achieve its' goals?
- tools
- standardized file locations

How to prepare a repository for use in Unity
In order to prepare a repository for automated builds and deployments certain 
standardized paths and filenames must be utilized so that Unity knows where 
to find them.
<!-- ☝️ Replace with a more detailed description of your repository, including why it was made and whom its intended for.  ☝️ -->

## Features

* build (perhaps not for all service areas -- but offered if they want it)
* unit test
* publish
* integration tests. (run U-CS end)
* deploy (U-CS)
* etc..
* This repo also houses the GitHub actions (push-button for now) that can trigger builds, tests, etc..
  
<!-- ☝️ Replace with a bullet-point list of your features ☝️ -->

## Contents

* [Quick Start](#quick-start)
  * [Automated Builds](#automated-builds)
  * [Unit Testing](#unit-testing)
  * [Automated Deployments](#automated-deployments)
  * [Smoke Testing](#smoke-testing)
  * [Teardown](#teardown)
* [Changelog](#changelog)
* [FAQ](#frequently-asked-questions-faq)
* [Contributing Guide](#contributing)
* [License](#license)
* [Support](#support)

## Quick Start

This guide provides a quick way to get started with our project. Please see our [docs]([INSERT LINK TO DOCS SITE / WIKI HERE]) for a more comprehensive overview.
Unity CS is a set of common components for the Unity project. The aim is to automate the process of building and deploying, providing developers with a transparent and seamless experience.

[Unity Docs](https://unity-sds.gitbook.io/docs/) | [Unity-CS Docs](https://unity-sds.gitbook.io/docs/developer-docs/common-services) | [Issue Tracker](https://github.com/unity-sds/unity-cs-infra/issues)

## Features

#### Requirements

* [INSERT LIST OF REQUIREMENTS HERE]
  
<!-- ☝️ Replace with a numbered list of your requirements, including hardware if applicable ☝️ -->

#### Setup Instructions

1. [INSERT STEP-BY-STEP SETUP INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]
   
<!-- ☝️ Replace with a numbered list of how to set up your software prior to running ☝️ -->

#### Run Instructions

1. [INSERT STEP-BY-STEP RUN INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your run instructions, including expected results ☝️ -->

#### Usage Examples

* [INSERT LIST OF COMMON USAGE EXAMPLES HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a list of your usage examples, including screenshots if possible, and link to external documentation for details ☝️ -->

#### Build Instructions (if applicable)

1. [INSERT STEP-BY-STEP BUILD INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your build instructions, including expected results / outputs with optional screenshots ☝️ -->

#### Test Instructions (if applicable)

1. [INSERT STEP-BY-STEP TEST INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your test instructions, including expected results / outputs with optional screenshots ☝️ -->

### Unit Testing
TBD

#### Requirements

* [INSERT LIST OF REQUIREMENTS HERE]
  
<!-- ☝️ Replace with a numbered list of your requirements, including hardware if applicable ☝️ -->

#### Setup Instructions

1. [INSERT STEP-BY-STEP SETUP INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]
   
<!-- ☝️ Replace with a numbered list of how to set up your software prior to running ☝️ -->

#### Run Instructions

1. [INSERT STEP-BY-STEP RUN INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your run instructions, including expected results ☝️ -->

#### Usage Examples

* [INSERT LIST OF COMMON USAGE EXAMPLES HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a list of your usage examples, including screenshots if possible, and link to external documentation for details ☝️ -->

#### Build Instructions (if applicable)

1. [INSERT STEP-BY-STEP BUILD INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your build instructions, including expected results / outputs with optional screenshots ☝️ -->

#### Test Instructions (if applicable)

1. [INSERT STEP-BY-STEP TEST INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your test instructions, including expected results / outputs with optional screenshots ☝️ -->

### Automated Deployments
Deployments are handled through Terraform.  Terraform scripts are stored in the 
terraform-unity directory in a repositorys root directory.  At deployment time 
the terraform scripts are validated and 

* Configurable AWS environment setup
* Build, Test, and Deploy automation
* Integration with GitHub actions
* Support for Automated Builds, Testing, Deployments, and Teardowns

## Contents

* [Quick Start](#quick-start)
* [Changelog](#changelog)
* [FAQ](#frequently-asked-questions-faq)
* [Contributing Guide](#contributing)
* [License](#license)
* [Support](#support)

## Quick Start

### Requirements

* AWS Account
* GitHub Actions setup
* Docker for running Unity workflows locally
  
### Setup Instructions

1. Clone the `unity-cs-infra` repository.
2. Configure your AWS credentials and environment variables.
3. Ensure your repository adheres to standardized file paths for Unity recognition.

### Run Instructions

1. Trigger the GitHub actions to initiate build, test, or deploy.
2. For local execution, pull the docker image and execute workflows using [Act](https://github.com/nektos/act). Act also makes use of docker so you need to pass the docker sock into the platform to be able to run it, as follows on a linux host:
   ```
   docker pull ghcr.io/unity-sds/unity-cs-infra:main 
   docker run -it -v //var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker ghcr.io/unity-sds/unity-cs-infra:main
   ```

### Usage Examples

* Automated Build: Set up `build.sh` as the common entry point for building.
* Deployments: Use Terraform scripts and maintain them in the `terraform-unity` directory.
* Testing: Ensure unit tests, smoketests, and integration tests are set up correctly.

### Build Instructions

1. Follow the standard Unity CS structure for your repository.
2. Utilize the `build.sh` script for a common build entry point.

### Test Instructions

1. Use `test.sh` for unit testing.
2. For smoke tests, ensure the tests are located in the `smoketest` directory.
3. Follow the directory structure for testing requirements.

### Deployment Instructions

Deployments are handled through Terraform. Terraform scripts are stored in the terraform-unity directory in a repositorys root directory. At deployment time the terraform scripts are validated.
```
.
└── terraform-unity
    ├── main.tf
    ├── networking.tf
    └── variables.tf
```


#### Requirements

* [INSERT LIST OF REQUIREMENTS HERE]
  
<!-- ☝️ Replace with a numbered list of your requirements, including hardware if applicable ☝️ -->

#### Setup Instructions

1. [INSERT STEP-BY-STEP SETUP INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]
   
<!-- ☝️ Replace with a numbered list of how to set up your software prior to running ☝️ -->

#### Run Instructions

1. [INSERT STEP-BY-STEP RUN INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your run instructions, including expected results ☝️ -->

#### Usage Examples

* [INSERT LIST OF COMMON USAGE EXAMPLES HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a list of your usage examples, including screenshots if possible, and link to external documentation for details ☝️ -->

#### Build Instructions (if applicable)

1. [INSERT STEP-BY-STEP BUILD INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your build instructions, including expected results / outputs with optional screenshots ☝️ -->

#### Test Instructions (if applicable)

1. [INSERT STEP-BY-STEP TEST INSTRUCTIONS HERE, WITH OPTIONAL SCREENSHOTS]

<!-- ☝️ Replace with a numbered list of your test instructions, including expected results / outputs with optional screenshots ☝️ -->
### Teardown Instructions

Teardowns are managed in the same way as deployments, through Terraform. The teardown workflow is supplied by Unity and requires no additional files in the target repository as long as the terraform-unity directory is set up correctly.

## Changelog

See our [CHANGELOG.md](CHANGELOG.md) for a history of our changes.

See our [releases page](https://github.com/unity-cs-infra/releases) for our key versioned releases.

## Frequently Asked Questions (FAQ)

No questions yet. Propose a question to be added here by reaching out to our contributors! See the support section below.

## Contributing

Interested in contributing to our project? Please see our: [CONTRIBUTING.md](CONTRIBUTING.md)

## License

See our: [LICENSE](LICENSE)

## Support

Key points of contact are: [@galenatjpl]https://github.com/galenatjpl
