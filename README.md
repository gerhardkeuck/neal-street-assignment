# Neal Street - Technical Assignment

This project serves as the deliverable for the Neal Street Senior Cloud Engineer Technical Assignment. It's broken into
the following parts:

1. **application:** Reference application acting as the dev web tier
1. **terraform:** For provisioning management and live AWS resources.
2. **ansible:** Ansible resources for application deployment and configuration.
3. **.github/workflows**: CI/CD workflows for validating/building/release/deploying changes.

## CI/CD flow

- **PR to `main`**: `Dev Plan Terraform` runs `fmt` + `validate` + `plan` and posts a sticky comment with
  the diff; `Verify App` runs Go fmt/vet/test/build; `Ansible Lint` checks the role.
- **Merge to `main`**: `Dev Apply Terraform` applies infra; `Dev Deploy App` runs the Ansible playbook
  over SSM against whatever EC2 the dynamic inventory finds; `Build App Release` publishes a tagged GitHub
  Release with the linux-arm64 binary.
- **Manual**: `Dev Deploy App` accepts `workflow_dispatch` with an explicit `binary_url`, which is the
  primary rollback lever.

All AWS calls use GitHub OIDC against the role provisioned by `terraform/management`, no static
credentials live in the repo or in CI secrets.

## Setup

### Install Required Tools

- terraform (≥ 1.10, required for native S3 state locking)
- ansible and ansible-lint
- Go SDK (only needed to build the app locally)
- AWS CLI v2 with the [Session Manager plugin]

### Prepare local AWS context

To run Terraform and Ansible locally, ensure the required tools are installed and the AWS session is correct.

Configure the local AWS session using:

- Hardcoded IAM access key and secret key
- SSO session

> ⚠️ Take care to ensure the current AWS context is for the correct account when making changes.
>
> Verify with `aws sts get-caller-identity`
>
> For this project, the account must be `696715199782`

## Environment Setup

When onboarding a new environment, ensure the required resources are provisioned and configured correctly.

### Bootstrapping environment

> Bootstrap is done locally and is a prerequisite for CI/CD operations.

Even though the majority of the Terraform operations are executed using Github Actions, the initial account and minimal
state resources must be created beforehand:

- The AWS account must be manually provisioned.
- An S3 bucket for Terraform state, versioning enabled, default encryption enabled, public access blocked.
- An IAM role/user for CI/CD execution against resources in the environment.
- A manually created Secrets Manager secret for the app secret, for example `/dev/rewards/config`.

> NOTE: Most examples in this project use the `dev` environment/workspace. For production, use `prod`.

1. First create the environment files under `terraform/env/`. Shared values go in `<workspace>.common.tfvars`,
   root-specific values go in `<workspace>.<root>.tfvars`, shared backend values go in
   `<workspace>.backend.common.hcl`, and root-specific backend keys go in
   `<workspace>.backend.<root>.hcl`. Where `<root>` is the name of the relevant module (`management`/`live`).
2. Create the required state management resources:

```shell
./terraform/bootstrap-backend.sh

# Note the bucket arn in the outputs, it should look something like:
#  tfstate-neal-street-696715199782-eu-west-1-an
```

3. This project also uses an example secret which is read from Secrets Manager. The secret is manually created for the
   sake of simplicity.

```shell
./terraform/create-example-secret.sh dev
```

4. Create the required IAM Roles that will be used by Github Actions to apply Terraform and execute Ansible playbooks.
   These resources will not be managed by GHA:

```bash
pushd terraform/management

terraform init \
  -backend-config=../env/dev.backend.common.hcl \
  -backend-config=../env/dev.backend.management.hcl

terraform workspace select -or-create dev

terraform apply \
  -var-file=../env/dev.common.tfvars \
  -var-file=../env/dev.management.tfvars

# Note the Github role arn in the outputs, which is used for configure the Github actions runner for this environment.
```

### Configure Github Actions

Before the GHA runner can execute Terraform or Ansible, the following must be configured:

- In Github, create an environment, eg. `dev`.
- On the created environment:
    - Set the `AWS_ROLE_ARN` variable to the role created by the `management` terraform module.


### Run Terraform locally

This shows how to run Terraform locally for the `dev` environment. This is not strictly required, as all `live` state
can be managed by GHA, though it can be useful for testing and debugging.

```bash
pushd terraform/live
terraform init \
  -backend-config=../env/dev.backend.common.hcl \
  -backend-config=../env/dev.backend.live.hcl

terraform workspace select -or-create dev
# Plan or apply
terraform plan \
  -var-file=../env/dev.common.tfvars \
  -var-file=../env/dev.live.tfvars
```

Format Terraform before committing and verify changes reflect expected changes (only if your role has required access,
otherwise review on a PR):

```shell
pushd <TF_MODULE>
terraform fmt -recursive
terraform validate
terraform plan \
  -var-file=../env/dev.common.tfvars \
  -var-file=../env/dev.live.tfvars
```

## Local Workflows

### Run Ansible locally

This shows how to run Ansible locally for the `dev` environment. This is not strictly required, as all deployments are
managed by GHA, though it can be useful for testing and debugging.

Ansible connects over SSM (no SSH, no public IPs). Requires `aws` CLI v2 with
the [Session Manager plugin], a sufficently privilaged AWS session (SSM, EC2 query, S3 for sync), and the collections
from `requirements.yaml`.

```shell
pushd ansible
ansible-galaxy collection install -r requirements.yaml

# Resolve the SSM transfer bucket created by Terraform (used by the aws_ssm connection plugin).
export ANSIBLE_SSM_BUCKET=$(cd ../terraform/live && terraform output -raw ansible_ssm_bucket_name)

ansible-inventory -i inventories/dev.aws_ec2.yaml --graph
ansible-playbook  -i inventories/dev.aws_ec2.yaml playbooks/deploy.yaml \
  --extra-vars "rewards_binary_url=<https-url-to-release-asset> rewards_commit_hash=<short-sha>"
```

> Local admin credentials are only used by the controller (inventory lookup + SSM
> channel). On-host actions (e.g. Secrets Manager reads) use the EC2 instance
> profile. CI uses a scoped role, not admin.

[Session Manager plugin]: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

**Format Ansible before committing**
```shell
cd ansible
ansible-lint --fix
```

### Example app

A minimal Go app is created to demonstrate:

- providing the public JSON health endpoint required by the brief
- reading the `APP_SECRET` from Secrets Manager via the EC2 instance profile (no static creds)
- surfacing build/runtime context (`commit`, `region`) in the health response

```shell
cd application
cp .env.example .env

# Run locally
go run .

# Tests
go test ./...

go vet ./...
```

## Cleanup resources

Remove resources for an environment:

```shell
# 1. Destroy environment infrastructure (NLB, ASG, EC2, SGs, S3, alarms, etc.)
pushd terraform/live
terraform workspace select dev
terraform destroy \
  -var-file=../env/dev.common.tfvars \
  -var-file=../env/dev.live.tfvars
popd

# 2. Destroy the GitHub Actions IAM role and management resources.
pushd terraform/management
terraform workspace select dev
terraform destroy \
  -var-file=../env/dev.common.tfvars \
  -var-file=../env/dev.management.tfvars
popd

# 3. Manually delete the externally provisioned secret.
aws secretsmanager delete-secret \
  --secret-id /dev/rewards/config \
  --force-delete-without-recovery
  
# 4. Manually delete the environment in Github. If planning to recreate the resources, this step can be skipped, since
# the role will be recreated with the same ARN.
```

Destroying the state backend impacts **every workspace** (dev and future prod), only do this when the whole project
is being retired:

```shell
./terraform/bootstrap-backend.sh
```
