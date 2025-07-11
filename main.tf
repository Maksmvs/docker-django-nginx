terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.28"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = "eu-central-1"
}

module "s3_backend" {
  source = "./modules/s3-backend"
}


module "s3_backend" {
  source             = "./modules/s3-backend"
  bucket_name        = "maksmvs-ci-cd-terraform-state"
  dynamodb_table_name = "terraform-locks"
}
