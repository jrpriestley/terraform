terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.68.0"
    }
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "./aws.credentials"
}