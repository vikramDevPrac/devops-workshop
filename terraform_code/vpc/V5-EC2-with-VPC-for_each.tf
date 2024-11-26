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
  ami = "ami-005fc0f236362e99f" #"ami-012967cc5a8c9f891"
  instance_type = "t2.micro"
  key_name = "devops-project2"
  #security_groups = [ "demo-sg" ]          
  vpc_security_group_ids = [ aws_security_group.demo-sg.id ]
  subnet_id = aws_subnet.demo-publis-subnet-1.id
  depends_on = [ aws_security_group.demo-sg ]
  for_each = toset(["Jenkins-master", "build-slave", "ansible"])
  tags = {
    Name = "${each.key}"
  }
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id      = aws_vpc.demo-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    description = "SSH Access"
  }
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    description = "Jenkins Access"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  tags = {
    Name = "demo-sg"
  }
}
resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "demo-vpc" 
  }
}

resource "aws_subnet" "demo-publis-subnet-1" {
  vpc_id = aws_vpc.demo-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1a"
  tags = {
    Name = "demo-public-subnet-1"
  } 
}

resource "aws_subnet" "demo-publis-subnet-2" {
  vpc_id = aws_vpc.demo-vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-1b"
  tags = {
    Name = "demo-public-subnet-2"
  } 
}

resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo-vpc.id
  tags = {
    Name = "demo-igw"
  }
}

resource "aws_route_table" "demo-public-rt" {
  vpc_id = aws_vpc.demo-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }
}

resource "aws_route_table_association" "demo-rta-public-subnet-1" {
  subnet_id = aws_subnet.demo-publis-subnet-1.id
  route_table_id = aws_route_table.demo-public-rt.id
}

resource "aws_route_table_association" "demo-rta-public-subnet-2" {
  subnet_id = aws_subnet.demo-publis-subnet-2.id
  route_table_id = aws_route_table.demo-public-rt.id
}

  module "sgs" {
    source = "../sg_eks"
    vpc_id     =     aws_vpc.demo-vpc.id
 }

  module "eks" {
       source = "../eks"
       vpc_id     =     aws_vpc.demo-vpc.id
       subnet_ids = [aws_subnet.demo-publis-subnet-1.id,aws_subnet.demo-publis-subnet-2.id]
       sg_ids = module.sgs.security_group_public
 }