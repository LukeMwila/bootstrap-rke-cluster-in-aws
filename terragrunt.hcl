generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
  provider "aws" {
     region  = "eu-west-1"
     profile = "serverless-deployer"
  }
  terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "2.57"
    }
}
  required_version = "~> 1.0.4"
  backend "s3" {}
  }
EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt                 = true
    bucket                  = "euw1-rke-terraform-state"
    key                     = "${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table          = "euw1-rke-terraform-lock-table"
    profile                 = "serverless-deployer"
    region                  = "eu-west-1"
  }
}