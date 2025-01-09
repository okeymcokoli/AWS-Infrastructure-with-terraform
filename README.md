# Terraform Infrastructure Module

This repository contains a Terraform configuration to deploy a simple web application infrastructure on AWS. The infrastructure consists of a VPC, public subnets, EC2 instances, an Application Load Balancer (ALB), security groups, and associated networking components. The goal is to provision a scalable and highly available web environment with load balancing.

## Table of Contents

- [Terraform Infrastructure Module](#terraform-infrastructure-module)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Getting Started](#getting-started)

---

## Prerequisites

Before you begin, ensure you have the following:

1. **Terraform** installed on your local machine. You can download it from [Terraform Downloads](https://www.terraform.io/downloads.html).
2. An **AWS account** with appropriate permissions to create resources like VPCs, EC2 instances, load balancers, etc.
3. AWS credentials (AWS Access Key and Secret Key) set up via environment variables or the AWS CLI. You can configure them with the command `aws configure`.

---

## Getting Started

1. Clone the repository:
   ```
   git clone <repository-url>
   cd <repository-folder>
Initialize the Terraform project:

sh
Copy code
terraform init
Review the resources to be created:

sh
Copy code
terraform plan
Apply the Terraform configuration to create the resources:

sh
Copy code
terraform apply
Terraform Configuration Overview
Provider Configuration
In provider.tf, the AWS provider is configured with the us-east-1 region:

hcl
Copy code
provider "aws" {
  region = "us-east-1"
}
This specifies the AWS region where the infrastructure will be created.

Resources
VPC
A VPC is created with the CIDR block defined by cidr_block and a name provided by vpc-name.

hcl
Copy code
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  instance_tenancy = "default"
  tags = {
    Name = var.vpc-name
  }
}
Subnets
Two public subnets are created in two different availability zones, with CIDR blocks 10.0.0.0/24 and 10.0.1.0/24.

hcl
Copy code
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[0]
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
}
hcl
Copy code
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[1]
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
Internet Gateway
An Internet Gateway is created and attached to the VPC.

hcl
Copy code
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.igw-name
  }
}
Route Table
A route table is created and associated with the public subnets, allowing internet access via the Internet Gateway.

hcl
Copy code
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
Security Group
A security group is created to allow HTTP (port 80) and SSH (port 22) traffic from anywhere (0.0.0.0/0).

hcl
Copy code
resource "aws_security_group" "sg" {
  name        = var.sg-name
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.sg-name
  }
}
EC2 Instances
Two EC2 instances are created with user data scripts. The instances are associated with the public subnets and the security group.

hcl
Copy code
resource "aws_instance" "webserver_1" {
  ami           = var.ami
  instance_type = var.instance-type
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = file("userdata.sh")
  tags = {
    Name = var.instance-name
  }
}
Application Load Balancer (ALB)
An Application Load Balancer is created, distributing traffic to the two EC2 instances.

hcl
Copy code
resource "aws_lb" "alb" {
  name               = var.alb-name
  load_balancer_type = "application"
  internal           = false
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.sg.id]
  tags = {
    Name = var.alb-name
  }
}
Variables
The module uses the following variables (defined in variables.tf):

vpc-name: Name of the VPC.
azs: List of availability zones for subnet placement.
cidr_block: CIDR block for the VPC.
sg-name: Name for the security group.
ami: Amazon Machine Image (AMI) ID for EC2 instances.
instance-type: Instance type for EC2 instances.
instance-name: Name for EC2 instance 1.
instance-name-2: Name for EC2 instance 2.
key-name: SSH key pair name (optional).
alb-name: Name for the Application Load Balancer.
tg-name: Name for the Target Group associated with the ALB.
You can customize these values in a terraform.tfvars file or directly via the command line.

Outputs
loadbalancerdns: The DNS name of the created ALB.
Usage
Customize Variables: Create a terraform.tfvars file or provide the required variables directly via the command line.

Example terraform.tfvars:


cidr_block = "10.0.0.0/16"
azs = ["us-east-1a", "us-east-1b"]
vpc-name = "my-vpc"
sg-name = "my-security-group"
ami = "ami-0c55b159cbfafe1f0"
instance-type = "t2.micro"
instance-name = "webserver-1"
instance-name-2 = "webserver-2"
alb-name = "my-alb"
tg-name = "my-target-group"
Run Terraform commands:

```
terraform init
terraform plan
terraform apply
```
Example
After applying the Terraform configuration, you will have:

A VPC with two public subnets.
Two EC2 instances running with the specified AMI and instance type.
An Application Load Balancer distributing traffic to the EC2 instances.
Security group rules allowing HTTP and SSH access from anywhere.
Cleaning Up
To destroy the resources and avoid ongoing charges, run:

```
terraform destroy
```

This will remove all the AWS resources created by Terraform.
# AWS-Infrastructure-with-terraform
