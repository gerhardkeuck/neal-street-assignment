# Management module

This module provisions the GitHub Actions OIDC provider and the workspace-scoped IAM role used by Terraform and
Ansible deploy workflows.

For dev:

```bash
pushd management

terraform init \
  -backend-config=../env/dev.backend.common.hcl \
  -backend-config=../env/dev.backend.management.hcl

terraform workspace select -or-create dev

terraform plan \
  -var-file=../env/dev.common.tfvars \
  -var-file=../env/dev.management.tfvars
```
