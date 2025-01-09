terraform {
  backend "s3" {
    region = "ap-southeast-1"
    bucket = "vinod-terraform-test-bucket"
    key = "merlion/dev/vpc-lattice-demo"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.82.2"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
