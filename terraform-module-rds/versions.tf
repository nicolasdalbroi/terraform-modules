terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.38"
    }
  }

}

provider "aws" {
  alias  = "secondary"
  region = "us-west-1"

}