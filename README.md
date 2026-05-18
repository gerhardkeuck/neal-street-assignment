# Neal Street - Technical Assigment

This project servers as the deliverable for the Neal Streat Senior Cloud Engineer Technical Assigment.

## How to use this repo

### Require CLI tools

[//]: # (TODO add links for specifics)

- terraform
- ansible
- go sdk
- aws cli

> ⚠️ Take care to ensure the current AWS context is for the correct account.
>
> Verify with `aws sts get-caller-identity`

### Bootstrapping account, state management and required resource access

Even though the majority of the Terraform operations are executed using Github Actions, the initial account and minial
state resources must be created beforehand:

- The AWS account must be manually provisioned.
- An S3 bucket for Terraform state, versioning enabled, default encryption enabled, public access blocked.
- An IAM role/user for local or CI Terraform execution.
- A manually created Secrets Manager secret for the app secret, for example `/dev/rewards/config`.

> NOTE: Most examples in the project use the `dev` environ/workspace. For production, use `prod`.

1. First create the environment files under `terraform/env/`. Shared values go in `<workspace>.common.tfvars`,
   root-specific values go in `<workspace>.<root>.tfvars`, and shared backend values go in
   `<workspace>.backend.common.hcl`.
2. Then create the required state resources:

```shell
cd terraform
./bootstrap-backend.sh

# Note the bucket arn in the outputs, it should look something like:
#  tfstate-neal-street-696715199782-eu-west-1-an
```

3. This project also uses an example secret which is read from Secrets Manager. The secret is manually created for the
   sake of simplicity.

```shell
cd terraform
./create-example-secret.sh dev
```

4. Create the required IAM Roles that will be used by Github Actions to apply Terraform and execute Ansible playbooks.
   These resources will not be managed by GHA:

```bash
push terraform/management

terraform init \
  -backend-config=../env/dev.backend.common.hcl \
  -backend-config=key=management/terraform.tfstate

terraform workspace select -or-create dev

terraform apply \
  -var-file=../env/dev.common.tfvars \
  -var-file=../env/dev.management.tfvars

# Note the Github role arn in the outputs, which is used for configure the Github actions runner for this environment.
```

### Run terraform locally

```bash
pushd terraform/live
terraform init \
  -backend-config=../env/dev.backend.common.hcl \
  -backend-config=key=rewards/terraform.tfstate

terraform workspace select -or-create dev
# Plan or apply
terraform plane \
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

### Configure Github Actions

Before the runner can execute terraform, the following must be configured:

- In Github, create an environment, eg. `dev`.
- On the created environment:
    - Set the `AWS_ROLE_ARN` variable to the role created by the `management` terraform module.

## Managing application configuration

### Secrets

## Example app

```shell
cd application
cp .env.example .env

# Run locally
go run .

# Tests
go test ./...
```
