terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    key = "terraform/state.tfstate"
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

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "test_profile"
  role = "EC2-ECR-AUTH"
}

resource "aws_instance" "server" {
  ami           = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.maingroup.id]
  iam_instance_profile = [aws_iam_instance_profile.ec2-profile]
  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = var.private_key
    timeout = "40"
  }
  tags = {
    "name" = "deployvm"
  }

}

resource "aws_security_group" "maingroup" {
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    self             = false 
  }
    ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key
}


output "instance_public_ip" {
    value = aws_instance.server.public_ip
    sensitive = true
}