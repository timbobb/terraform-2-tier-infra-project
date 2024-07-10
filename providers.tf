terraform {
  # configure the remote backend
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Nife-Terraform-Projects"
    workspaces {
      name = "2-tier-architecture"
    }
  }
  #required providers block
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"
    }
  }
}

# configure the AWS provider
provider "aws" {
  region = "us-east-1"
}