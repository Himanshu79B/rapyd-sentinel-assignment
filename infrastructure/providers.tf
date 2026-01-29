terraform {
  required_version = "~> 1.14"

  backend "s3" {
    bucket                   = "himanshu-bhimwal-devops-assignment-terraform"
    key                      = "infrastructure/terraform.tfstate"
    region                   = "us-east-2"
    profile                  = "rapyd"
    shared_config_files      = ["~/.aws/config"]
    shared_credentials_files = ["~/.aws/credentials"]
    use_lockfile             = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}

provider "aws" {
  region                   = "us-east-2"
  profile                  = "rapyd"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]

  assume_role {
    role_arn = "arn:aws:iam::721500739616:role/sentinel-terraform"
  }

  default_tags {
    tags = local.default_tags
  }
}
