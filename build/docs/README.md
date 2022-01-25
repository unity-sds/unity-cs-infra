# Unity Commom Services Deployment Workflow

1. Retrieve Deployment Catalog
    Deployments will be triggerd manually or by updates to the Deployment Catalog.  The Catalog must include changes to the infrastructure as well as a list of artifacts and destinations.

1. Apply Configuration Values
    Before executing any deployment scripts the sensitive values will be applied to the infrastructure scripts and any system configuration files that need api keys or other configurations in place to run properly.  

    These values should be kept somewhere secure like Ansible Vault.

1. Run Infrastructure Scripts (Terraform)
    These scripts will set up our infrastructure inside of our deployment environment (in this case AWS)

1. Deploy Artifacts to Infrastructure
    The list of Artifacts can include code, docker containers, static files, anything that is not a part of the infrastructure configuration.

1. Test Deployment
    At the bare minimum, there should be a smoke test included that will check for a successful deployment of the system