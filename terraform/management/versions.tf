terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket               = "tfstate-neal-street-696715199782-eu-west-1-an"
    key                  = "management/terraform.tfstate"
    region               = "eu-west-1"
    workspace_key_prefix = "env"
    encrypt              = true
    use_lockfile         = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
