generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
  provider "aws" {
     region  = "eu-west-1"
     profile = "your-aws-profile"
  }
  terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "2.57"
    }
}
  required_version = "~> 1.1.2"
  backend "s3" {}
  }
EOF
}

remote_state {
  backend = "s3"
  config = {
    encrypt                 = true
    bucket                  = "your-terraform-state-bucket"
    key                     = "${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table          = "your-terraform-lock-table"
    profile                 = "your-aws-profile"
    region                  = "eu-west-1"
  }
}
