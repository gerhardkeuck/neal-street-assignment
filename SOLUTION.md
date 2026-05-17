# Solution

**Terraform state handling approach**

Terraform state files are stored in S3. This enabled the state to be shared when multiple client.

Using a minimal Caddy server for

- Include AI prompts and reason for the prompts
- Choice for Github Actions:
    - Support for protected environment with approval for environment, ie. prod.
    - Required Apply on merge. Atlantis only support automerge after apply.

- Promotion process.
    - Option 1: Ansible and Terraform tied
        - Apply terraform on merge to main. Block deploy until complete.
        - Deploy latest version to dev account using

**Structing modules between environments**
For this assigment a single AWS account was used, given the assigment constraints. Only the `dev` environment has been
provisioned. In a production rollout, I would promote the same Terraform/Ansible pattern into a
separate prod AWS account, using a distinct Terraform backend/state path, separate GitHub OIDC IAM role, separate secret
namespace, and manual approval before apply. This keeps blast radius, credentials, and audit boundaries separate without
adding unnecessary complexity to the dev exercise.

**Ansible EC2 authentication and management**
The solution accounts for dynamic EC2 instances in the inventory (at the time of deploy). This is achieved through by
using the Ansible AWS dynamic inventory plugin. Access is managed throuhg AWS SSM and appropriately scoped least
privilege

The instances for the relevant service and environment is scoped and the

## Current limitations

Due to the native of the Ansible based application deployment, if an instance is added, the application will not yet be
running there and will require an explicit deploy trigger.
The ALB won't route traffic to that instance until the health endpoint is ready, so the current solution wont affect
unexpected 502.

## Improvements

SSO session for management roles, to avoid hardcoded IAM secrets on machine.

## Appendices

### Relevant web links

- [Dynamic AWS Inventory for Ansible](https://docs.ansible.com/projects/ansible/latest/collections/amazon/aws/docsite/aws_ec2_guide.html)
- https://developer.hashicorp.com/terraform/language/backend/s3#s3-bucket-permissions

### LLM Prompts used

With pure Terraform (ie. without Terragrunt) the state backend needs to be manually provisioned in advance (or created
from another Terraform project/account). Used in `setup-state-backend.sh`:

```
create an s3 state bucket equivalent to terragrunt s3 bucket, using s3 lockfile, not dynamodb, using the aws cli in a shell script.
use an account regional namespaced bucket.
aws encryption, versioning enabled.

ensure the setup-state-backend.sh has basic idempotency
```

Creating a skeleton application for exposing the health endpoint

```
create a minimal gin application using latest gin, go sdk and aws packages.
expose a single GET endpoint on /health and return a JSON body  {"service":"rewards","status":"ok","commit":"","region":""}
get the Region from IMD2S on server start.
read the COMMIT_HASH and SECRET_PATH from environment variables.
read the secret from secrets managed at the given path, asset the secret has key APP_SECRET and log that is has the secret to stderr.
create minimal github actions workflows to:
1. for PRs verify lint, fmt and run tests
2. on push to main: build the binary for linux arm64 and publish as github release artifact, use simplified tags for the releases
```
