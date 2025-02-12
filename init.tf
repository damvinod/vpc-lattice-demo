terraform {
  backend "s3" {
    region       = "ap-southeast-1"
    bucket       = "vinod-terraform-test-bucket"
    key          = "merlion/dev/vpc-lattice-demo"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.86.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
