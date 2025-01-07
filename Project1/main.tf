provider "aws" {
  region  = "ap-south-1"
  profile = "my_profile"
}

#####  aws configure --profile my_profile


# 1 Create VPC

resource "aws_vpc" "Pro1_main" {
  cidr_block = "10.0.0.0/16"
   tags = {
    Name = "main_VPC"
  }
}


# 2 Create Internet Gateway 

resource "aws_internet_gateway" "Pro1_IG" {
  vpc_id = aws_vpc.Pro1_main.id

  tags = {
    Name = "main_IG"
  }
}


# 3 Create Custom Route table 

resource "aws_route_table" "Pro1_route_table" {
  vpc_id = aws_vpc.Pro1_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Pro1_IG.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.Pro1_IG.id  # Corrected reference
  }

  tags = {
    Name = "main_RT"
  }
}


# 4 Create a Subnet

resource "aws_subnet" "Pro1_Subnet" {
  vpc_id            = aws_vpc.Pro1_main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "main_SUBNET"
  }
}


# 5 Assocate subnet with route table 

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Pro1_Subnet.id
  route_table_id = aws_route_table.Pro1_route_table.id
}


resource "aws_security_group" "allow_tls" {
  name        = "allow-ssh-http-https"
  description = "Security group to allow SSH, HTTP, and HTTPS"
  vpc_id      = aws_vpc.Pro1_main.id

  # Ingress rules
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the world
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "allow-ssh-http-https"
  }
}


# 7 Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "Pro1_Interface" {
  subnet_id       = aws_subnet.Pro1_Subnet.id
  private_ips     = ["10.0.1.22"]
  security_groups = [aws_security_group.allow_tls.id]

  
}


# 8 assign an elastic IP to the network interface created in step 7  
# Delopying an elastic IP you must need an Internet gateway even if in terraform order don't matter but still
# for this we need a Internet gatway first

resource "aws_eip" "Por1_E" {
  network_interface = aws_network_interface.Pro1_Interface.id
  associate_with_private_ip = "10.0.1.22"
  depends_on = [aws_internet_gateway.Pro1_IG]
}


# 9 Create ubantu server and install/enable apache2   

resource "aws_instance" "web_server_Pro1" {
  ami= "ami-053b12d3152c0cc71"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "Pro1_Terraform_main" 

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.Pro1_Interface.id
  }

user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo bash -c 'echo "yup you did it" > /var/www/html/index.html'
              EOF
tags = {
  Name = "Web0set"
  }            
}
