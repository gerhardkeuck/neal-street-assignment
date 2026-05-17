# Neal Street - Technical Assigment

This project servers as the deliverable for the Neal Streat Senior Cloud Engineer Technical Assigment.

## How to use this repo

### Require CLI tools

[//]: # (TODO add links for specifics)
- terraform
- aws cli

> ⚠️ Before excecuting any of the AWS or Terraform commands, ensure the correct AWS profile has been configured.

**Accessing AWS Account**
To keep this solution simple, direct IAM access keys and secrets are used to authenticate

### Bootstrapping account

The AWS account is manually provisioned with:

- An S3 bucket for Terraform state, versioning enabled, default encryption enabled, public access blocked.
- An IAM role/user for local or CI Terraform execution.
- A manually created Secrets Manager secret for the app secret, for example `/dev/rewards/config`.


Even though the majority of the Terraform operations are executed using Github Actions, the initial account and minial state and access related resources must be created beforehand. The following scripts collects the minimal required access:


```shell
cd terraform
./setup-state-backend.sh
./setup-ci-access-role.sh
./create-example-secret.sh
```

> ⚠️ Take care to ensure the current AWS context is for the correct account.
> 
> Verify with `aws sts get-caller-identity`

### Run terraform locally

```bash
cd terraform/live
terraform init
terraform workspace select dev || terraform workspace new dev
terraform fmt -recursive
terraform validate
terraform plan -var-file=../envs/dev.tfvars
terraform apply -var-file=../envs/dev.tfvars
```


**Create state bucket**

Execute `setup-state-backend.sh`. Take care to ensure the current AWS context is for the correct account. 

## Managing application configuration

### Secrets

### 