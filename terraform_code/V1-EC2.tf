terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "demo-server" {
  ami = "ami-012967cc5a8c9f891"
  instance_type = "t2.micro"
  key_name = "devops-project2"
  
}