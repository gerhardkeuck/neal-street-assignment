# Solution

**Terraform state handling approach**

Instead of storing state locally and commiting it to the repo or using some form of manual state distribution, this
project
uses the S3 backend to securely store state. A locking files is used per module, to enable concurrent operation between
environments.


[//]: # (TODO explain tradeoffs and suitability for small teams)

Compared to local state this does require some additional setup, although this is a once off execise.

**Networking**
A VPC is created per environment, ensuring no shared routing between `dev` and `prod` environments.
Separate Public and Private subnets are used to separate traffic between public ingress for load balancers and private
traffic between load balancers and application servers.

Using a Network Loadbalancer as that can be deployed to a single AZ (compared to ALB).

**Example app**

An example Golang application is used to provide the health endpoint. It receives necessary configuration by reading a
.env file.

[//]: # (TODO example)

- Promotion process.
    - Option 1: Ansible and Terraform tied
        - Apply terraform on merge to main. Block deploy until complete.
        - Deploy latest version to dev account using

[//]: # (TODO rollbacks?)

**Secret management**
The sample APP_SECRET value is stored outside source control in a Secrets Manager secret. During deploy, Ansible fetches
the secret using the SSM session and renders it into /etc/rewards/app.env.
Secret-handling tasks use no_log: true to avoid leaking values into CI logs. This keeps secrets out of the
repository, while accepting the operational trade-off that the secret exists on disk on the instance.

For this project I chose rendering the secrets with Ansible, though in practice I would
prefer to retrieve secrets directly from AWS Secrets Manager. This limits secret persistence to disk en ensure secrets
will not be visible to Ansible logs or other deployment related runners.

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

**CI/CI configuration**

This project uses Github and Github Actions for managing CI/CD piplines. This was chosen for the following reasons:

- Protected environments available on free public repositories (compared to Gitlab).
- Requirement for Terraform apply on merge. This rulled out Atlantis.
- Support reviewers for protected environments.
- IAM OIDC auth between Gitlab Actions and AWS SSM is a straight forward and tested solution.

Ansible remotely connects using AWS SSM to all EC2 instances for a given environment and service (at that point in
time). The instances are discovered using the Ansible dynamic inventory plugin.

## Current limitations

Due to the nature of the Ansible based application deployment, if an instance is added or the scaling group churns, the
application will not automatically be deployed and started on the new instances. In this case, an explicit deployment is
required to trigger the application to start.

[//]: # (TODO review this)
Regardless of the app not runner, the ALB won't route traffic to that instance until the health endpoint is ready, so
the current solution won't affect unexpected 502 in the context of new instances being added. If there is sufficient
churn to fully rotate the ec2 instance pool, then there won't be any available instance, in which case there will likely
be a 502.

## For production

Access should be more tightly controlled for production related resources, especially management roles that have admin
level access to prod resources. In a single account configuration and would be more relevant with multi-account
topologies.

## Improvements

SSO session for management roles, to avoid hardcoded IAM secrets on machine. Only relevant for local module development.

## Appendices

### Relevant web links

- [Dynamic AWS Inventory for Ansible](https://docs.ansible.com/projects/ansible/latest/collections/amazon/aws/docsite/aws_ec2_guide.html)
- Setup required permissions for accessing state
  bucket ([S3 Bucket Permissions](https://developer.hashicorp.com/terraform/language/backend/s3#s3-bucket-permissions))

### LLM Prompts used

With pure Terraform (ie. without Terragrunt) the state backend needs to be manually provisioned in advance (or created
from another Terraform project/account). Used in `setup-state-backend.sh`:

```
create an s3 state bucket equivalent to terragrunt s3 bucket, using s3 lockfile, not dynamodb, using the aws cli in a shell script.
use an account regional namespaced bucket.
aws encryption, versioning enabled.

ensure the setup-state-backend.sh has basic idempotency
```

Add IPv6 support on VPC to be able to use IPv6 internet eggress on EC2 instance, to avoid requirement for NAT gateway.
```
add support for ipv6 ips on this vpc. add dns64, ensure ipv4 endpoints are still resolveable.
```

Creating a skeleton application for exposing the health endpoint:

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
