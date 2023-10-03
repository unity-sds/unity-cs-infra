<hr>

<div align="center">

![logo](https://user-images.githubusercontent.com/3129134/163255685-857aa780-880f-4c09-b08c-4b53bf4af54d.png)

<h1 align="center">unity-cs-infra</h1>

</div>

<pre align="center">A framework for configuring AWS environments for Unity CS operations.</pre>

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md) [![SLIM](https://img.shields.io/badge/Best%20Practices%20from-SLIM-blue)](https://nasa-ammos.github.io/slim/)

Unity CS is a set of common components for the Unity project. The aim is to automate the process of building and deploying, providing developers with a transparent and seamless experience.

[Unity Docs](https://unity-sds.gitbook.io/docs/) | [Unity-CS Docs](https://unity-sds.gitbook.io/docs/developer-docs/common-services) | [Issue Tracker](https://github.com/unity-sds/unity-cs-infra/issues)

## Features

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
