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
- A manually created SSM SecureString parameter for the app secret, for example `/rewards/dev/APP_SECRET`.

The majority of the terraform operations are executed using Github Actions, though the initial account and minial state and access must be beforehand.

Setup required permissions for accessing state bucket ([S3 Bucket Permissions](https://developer.hashicorp.com/terraform/language/backend/s3#s3-bucket-permissions))


**Create state bucket**

Execute `setup-state-backend.sh`. Take care to ensure the current AWS context is for the correct account. 

## Managing application configuration

### Secrets

### 