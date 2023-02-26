terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.0"
    }
  }

  backend "s3" {
    bucket = "gamma-infra-terraform"
    key    = "tfstate/"
    region = "ap-southeast-1"

  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}