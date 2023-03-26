terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  #region = "us-east-1"
  region  = "ap-southeast-1" #Asia Pacific (Singapore)#
  profile = "cloud-admin"    #iam-user #
}
