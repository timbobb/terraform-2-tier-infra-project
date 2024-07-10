# Create VPC
resource "aws_vpc" "TF_VPC" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "2-tier-VPC"
  }
}

# Create Public Subnets
# Public Subnet 1
resource "aws_subnet" "Public1" {
  vpc_id                  = aws_vpc.TF_VPC.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 1"
  }
}

# Public Subnet 2
resource "aws_subnet" "Public2" {
  vpc_id                  = aws_vpc.TF_VPC.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "us-east-1d"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 2"
  }
}

# Create Private Subnets
# Private Subnet 1
resource "aws_subnet" "Private1" {
  vpc_id                  = aws_vpc.TF_VPC.id
  cidr_block              = "10.10.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 1"
  }
}

# Private Subnet 2
resource "aws_subnet" "Private2" {
  vpc_id                  = aws_vpc.TF_VPC.id
  cidr_block              = "10.10.4.0/24"
  availability_zone       = "us-east-1d"
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 2"
  }
}

# Create Internet Gateway for Public Subnets
resource "aws_internet_gateway" "TF_IGW" {
  vpc_id = aws_vpc.TF_VPC.id
}

# Create Elastic IP for NAT gateway
resource "aws_eip" "NAT_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.TF_IGW]
}

# Create NAT Gateway for Private Subnets
resource "aws_nat_gateway" "TF_NATGW" {
  allocation_id = aws_eip.NAT_eip.id
  subnet_id     = aws_subnet.Public1.id
  depends_on    = [aws_eip.NAT_eip]
}

# Create Public Route Table
resource "aws_route_table" "TF_Public_Route" {
  vpc_id = aws_vpc.TF_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TF_IGW.id
  }
}

# Create Private Route Table
resource "aws_route_table" "TF_Private_Route" {
  vpc_id = aws_vpc.TF_VPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.TF_NATGW.id
  }
}

# Create Public Subnets Route Table Association
# Public Subnet 1
resource "aws_route_table_association" "Public1" {
  subnet_id      = aws_subnet.Public1.id
  route_table_id = aws_route_table.TF_Public_Route.id
}

# Public Subnet 2
resource "aws_route_table_association" "Public2" {
  subnet_id      = aws_subnet.Public2.id
  route_table_id = aws_route_table.TF_Public_Route.id
}

# Create Private Subnets Route Table Association
# Private Subnet 1
resource "aws_route_table_association" "Private1" {
  subnet_id      = aws_subnet.Private1.id
  route_table_id = aws_route_table.TF_Private_Route.id
}

# Private Subnet 2
resource "aws_route_table_association" "Private2" {
  subnet_id      = aws_subnet.Private2.id
  route_table_id = aws_route_table.TF_Private_Route.id
}

# Create Security Group for Apache EC2 instances 
resource "aws_security_group" "apache_SG" {
  name        = "apache_SG"
  description = "Allow SSH, Web traffic and all outbound traffic"
  vpc_id      = aws_vpc.TF_VPC.id

  tags = {
    Name = "apache-TF-SG"
  }

  # Create Ingress Rule to allow Web Traffic from any IP
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  # Create Ingress Rule to allow SSH from any IP
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  # Create Egress Rule
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

# Create 1 EC2 instance in each Web tier Public Subnet with Apache server
# 1st server
resource "aws_instance" "apache_server1" {
  ami                         = "ami-06c68f701d8090592"
  instance_type               = "t2.micro"
  key_name                    = "Nife-LUIT-KEYS"
  vpc_security_group_ids      = [aws_security_group.apache_SG.id]
  subnet_id                   = aws_subnet.Public1.id
  associate_public_ip_address = true
  tags = {
    Name = "apache-server1"
  }

  user_data = <<-EOF
    #!/bin/bash

    # update all packages on the server
    yum update -y

    # install apache web server
    yum install httpd -y

    # start apache
    systemctl start httpd

    # enable apache to automatically start when system boots up
    systemctl enable httpd

    EOF

}

# Create 2nd server
resource "aws_instance" "apache_server2" {
  ami                         = "ami-06c68f701d8090592"
  instance_type               = "t2.micro"
  key_name                    = "Nife-LUIT-KEYS"
  vpc_security_group_ids      = [aws_security_group.apache_SG.id]
  subnet_id                   = aws_subnet.Public2.id
  associate_public_ip_address = true
  tags = {
    Name = "apache-server2"
  }

  user_data = <<-EOF
    #!/bin/bash

    # update all packages on the server
    sudo yum update -y

    # install apache web server
    sudo yum install httpd -y

    # start apache
    sudo systemctl start httpd

    # enable apache to automatically start when system boots up
    sudo systemctl enable httpd

    EOF

}

# Create RDS Instance Security Group
resource "aws_security_group" "RDS_SG" {
  name        = "RDS_SG"
  description = "Allows inbound MySQL traffic and allows all outbound traffic from the RDS instance"
  vpc_id      = aws_vpc.TF_VPC.id

  tags = {
    Name = "RDS-TF-SG"
  }

  # Create Ingress Rule to allow inbound MySQL traffic from the Web server security group
  ingress {
    security_groups = [aws_security_group.apache_SG.id]
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
  }
  # Create Egress Rule to allow all outbound traffic from the RDS instance
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

# Create Subnet Group for Private RDS Instance
resource "aws_db_subnet_group" "RDS_subnet_group" {
  name       = "rds-db"
  subnet_ids = [aws_subnet.Private1.id, aws_subnet.Private2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# Create RDS Instance in  Private Subnets
resource "aws_db_instance" "RDS_instance" {
  allocated_storage      = 10
  db_name                = "myrds"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "nife"
  password               = "Mypassword"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.RDS_subnet_group.id
  vpc_security_group_ids = [aws_security_group.RDS_SG.id]
}