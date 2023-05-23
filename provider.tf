terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# retrive the current region
data "aws_region" "current" {}

# retrive the current account caller id
data "aws_caller_identity" "current" {}

locals {
  acc_id = data.aws_caller_identity.current.account_id
  region_id = data.aws_region.current.name
}

variable "cluster_name" {
  default = "demo"
}

variable "cluster_version" {
  default = "1.22"
}
