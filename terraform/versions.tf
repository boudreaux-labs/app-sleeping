terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "boudreaux-labs-terraform-state"
    key            = "app-sleeping/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "boudreaux-labs-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
