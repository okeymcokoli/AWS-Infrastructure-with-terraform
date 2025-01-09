#Create a VPC for your infrastructure
resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = var.vpc-name
  }
}

#Create two public subnets in 2 availability zones
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[0]
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[1]
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

}

#Create internet gateway for the specified VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.igw-name
  }
}

#Create a route table for the public subnets
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#Associate the route table with the public subnets
resource "aws_route_table_association" "route_table_association_1" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "route_table_association_2" {
  route_table_id = aws_route_table.RT.id
  subnet_id      = aws_subnet.public_subnet_2.id
}

#Create a security group for your EC2 instances
resource "aws_security_group" "sg" {
  name        = var.sg-name
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
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

# #Create a key pair for your EC2 instances
# resource "aws_key_pair" "key_pair" {
#     key_name   = var.key-name
#     public_key = file(var.public-key-path)
# }

#Create an EC2 instance
resource "aws_instance" "webserver_1" {
  ami           = var.ami
  instance_type = var.instance-type
  #key_name     = var.key-name
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = file("userdata.sh")

  tags = {
    Name = var.instance-name
  }
}
resource "aws_instance" "webserver_2" {
  ami           = var.ami
  instance_type = var.instance-type
  #key_name     = var.key-name
  subnet_id              = aws_subnet.public_subnet_2.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = file("userdata2.sh")

  tags = {
    Name = var.instance-name-2
  }
}

#Create alb for the 2 instances
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

resource "aws_alb_target_group" "tg" {
  name        = var.tg-name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/"
    port                = "traffic-port"
  }

}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_alb_target_group.tg.arn
  target_id        = aws_instance.webserver_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_alb_target_group.tg.arn
  target_id        = aws_instance.webserver_2.id
  port             = 80
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_alb_target_group.tg.arn
  }

}

#Outputs
output "loadbalancerdns" {
  value = aws_lb.alb.dns_name
}