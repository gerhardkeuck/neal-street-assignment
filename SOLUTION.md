# Solution

## Tasks breakdown order

[//]: # (TODO capture logical sequence of tasks)

High level task sequence breakdown, accounting for dependencies between tasks:

- Create minimal Go app to expose endpoint and generated logs
- GHA for go app: Test, build and release on Github Actions.
- Create terraform backend bootsrap.
- Create `managed` resources, for GHA to use Ansible and Terraform.
    - Role to assume, SSM to EC2, sufficient admin for Terraform management.
- Create `dev` environment Terraform resources.
- Workflows for plan & apply TF for dev
- Create ansible playbook for deploying from GitHub.
- Configure logging with cloudwatch logs.
- Teardown steps.
- Smoke test solution.

Continuously update README.md and SOLUTION.md while progressing.

## Reasoning for decisions

This project quite a white scope of decisions that had to be taken into account to deliver the solution within the
project constraints. Here the high level reasons for choices are explained.

**Terraform state handling approach**

Instead of storing state locally and commiting it to the repo or using some form of manual state distribution, this
project
uses the S3 backend to securely store state. A locking files is used per module, to enable concurrent operation between
environments.


[//]: # (TODO explain tradeoffs and suitability for small teams)

Compared to local state this does require some additional setup, although this is a once off exercise.

A simple shell script was used for the state bucket provisioning, this is needed to solve the catch-22 before Terraform
state can be stored. This step could normally be managed with Terragrunt.

**Multiple Terraform projects**

There are two parts for the Terraform solution:

- The `management` module provisions the required resources for the Github Actions runners to have necessary access to
  AWS. This need to be run manually beforehand.
- The `live` module provisions infrastructure for the `dev` (and `prod` if vars are defined) environments. This module
  can be fully managed through git PRs.

**Consistent tagging**

Defaults for tags are defined on the AWS provider to ensure all resources that support tags include those tags.

**Networking**
A VPC is created per environment, ensuring no shared routing between `dev` and `prod` environments.
Separate Public and Private subnets are used to separate traffic between public ingress for load balancers and private
traffic between load balancers and application servers.

Using a Network Loadbalancer as that can be deployed to a single AZ (compared to ALB).

**Example app**

Create a minimal app, to demonstrate logging to Cloudwatch logs.

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
For this assignment a single AWS account was used, given the assignment constraints. Only the `dev` environment has been
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

**Enforce GitHub PRs**

Created a GitHub ruleset to protec the `main` branch. This PRs must always be used and required checks will always be
executed.

Ruleset rules:

- Target branch: default
- Require a pull request before merging
- Require status checks to pass
- Require linear history
- Restrict deletions
- Block force pushes

## Current limitations

Due to the nature of the Ansible based application deployment, if an instance is added or the scaling group churns, the
application will not automatically be deployed and started on the new instances. In this case, an explicit deployment is
required to trigger the application to start.

[//]: # (TODO review this)
Regardless of the app not runner, the NLB won't route traffic to that instance until the health endpoint is ready, so
the current solution won't affect unexpected 502 in the context of new instances being added. If there is sufficient
churn to fully rotate the ec2 instance pool, then there won't be any available instance, in which case there will likely
be a 502.

## For production

- For general terraform usage, access should be managed via least privilage for production related resources. Less
  practical in a single account configuration and would be more relevant with multi-account.
- Separate Github assume roles for production deploys. Scope OIDC access to main branch on git repo.
- Application distributed, even though this was mostly out of scope, would be managed with private repos. For example
  private Github repo, S3 for artifacts, containers in ECR.

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

Add IPv6 support on VPC to be able to use IPv6 internet eggress on EC2 instance, to avoid requirement for NAT gateway (
to reduce costs, on a demo example, the NAT Gateway is x10 the cost of the single EC2 instance).

```
add support for ipv6 ips on this vpc. add dns64, ensure ipv4 endpoints are still resolveable.
```

```
adjust this to use a network loadbalancer and not alb https://registry.terraform.io/modules/terraform-aws-modules/autoscaling/aws/latest#usage
```

Need to allow access to the private EC2 instances. Use AWS STS for assuming roles, SSM and Ansible Dynamic Inventory for
deploys.

```
Review how to add dynamic inventories to ansible: https://docs.ansible.com/projects/ansible/latest/collections/amazon/aws/docsite/aws_ec2_guide.html
Ansible should conect to instances using aws ssm. Instances are on a private subnet, though that shouldnt affect the connection.
The ansible controller must run from a github actions workflow, create a minimal reference workflow running the ansible controller
with a mock playbook (create directory /etc/rewards). Create minimal reference terraform to define the github oidc connection and
required IAM policy for the role used by ansible (add reference in gha workflow where role is referenced).
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

Add logging for app:

```
review the go app, add some log messages that will show up in cloudwatch
```

Github role configuration:

```
are separate roles neede between github actions applying terraform and running ansible with dynamic inventory to apply application deployments? i meant, shouldnt it be fine to have a single AWS_ROLE_ARN on the dev environment which are then
  used by the terraform plan/apply and ansible deploy (all running in github actions). the management module should only provision the role with sufficient permissions to assume a role with oidc. the relevant iam module in the live module is
  responsible for configuring further access. idea being the role can add addition needed access, eg. to access ec2 instances. which would enable support for a 0-1 terraform apply for an environment.

update the modules to reflect that. also ensure the management module has sufficiently loose permissions to manage the env/dev path
```

Debug dualstack configuration between NLB and EC2 instances:

```
given the network/vpc setup uses dualstack, review the terraform compute and loadbalancer modules if there should be any config adjustments to account for dualstack networking. the requirement is that the app instances can make networking
  calls over ipv6, support ssm connections
```

Triage using Ansible dynamic inventory for EC2 deployments. It seems like the correct approach, though will not ensure
instances are up to date during churn:

```
from the docs, when deploying using github actions, it seems they want to apply terraform to dev and then deploy to dev, the amount of ec2 instances can be changed (so I'm assuming they mean autoscaling group?), so would also need ansible to be able to dynamically determine which hosts to connect to. should ansible be running using the shared github actions runners, that can work if using oidc iam.

wrt. to app deployment and updates, is this the relevant solution for deploying to  a variable amoutn of ec2 instance?
https://docs.aws.amazon.com/systems-manager/latest/userguide/integration-github-ansible.html
edge case when deployed using ansible on github actions, if the instance rotate post deploy, the new instance wont have
the required systemd/app/firewall configured. a lambda could be used, though this seems more like hack and could possibly
cause disjoint disployed verions if the sampled git tag (ie. what was last deployed for a given environemnt) could vary due to concurrency
```

Review missing steps:

```
create a dependency diagram to guide the implementation sequence of this project (task dependencies):
- minimal go app that builds with gha on main, tests on PRs, create public gh releases
- vpc, network routes, dualstack ipv6, support internet ipv6 egress from ec2 machines
- the ec2 instances with asg, managed instance group
- network loadbalancer, nlb
- security groups, between nlb and ec2, public ingress to nlb
- gitlab role required by ansible on github actions to manage terraform and deploy to instances
- ansible playbook using dynamic inventory targetting the environment/service of the managed ec2 instances, connect with ssm
- app deployed: local in ubuntu, secure disk rights, firewall rules,
- testing access to the nlb
```
