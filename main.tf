provider "aws"{
    region = "us-west-01"
        profile = "wordpress"
}

resource "aws_vpc" "myvpc" {
    cidr_block = "10.0.0.0/16"
    instant_tenancy = "default"

    tags = {
        Name = "wp-vpc"
    }
}

resource "aws_subnet" "wpsn1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "wp-sn-1a"
  }
}

resource "aws_subnet" "wpsn2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1b"

  tags = {
    Name = "wp-sn-1b"
  }
}

resource "aws_internet_gateway" "wpgw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "wp-gw"
  }
}

resource "aws_route_table" "wprt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wpgw.id
  }

  tags = {
    Name = "wp-rt"
  }
}

resource "aws_main_route_table_association" "wprtasso" {
  vpc_id         = aws_vpc.wpsn1.id
  route_table_id = aws_route_table.wprt.id
}

resource "aws_security_group" "sg-mywp" {
  name        = "WordPress-sg"
  description = "Allow TSSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "SSH traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

    ingress {
    description      = "Ping"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WordPress-sg"
  }
}

resource "aws_security_group" "sg-mysql" {
  name        = "Mysql-sg"
  description = "Allow WordPress inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "WordPress traffic"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [ aws_security_group.sg-mywp.id ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  depends_on = [
    aws_security_group.sg-mywp
  ]

  tags = {
    Name = "Mysql-sg"
  }
}

resource "aws_instance" "Mysql-OS" {
  ami           = "ami-0487b1fe60c1fd1a2"
  instance_type = "t2.micro"
  key_key_name = "mynewkey"
  aassociate_public_ip_address = true
  subnet_id = aws_subnet.wpsn2.id  
  vpc_security_group_ids = [ aws_security_group.sg-mysql.id ]
  availability_zone = "us-west-1b"

   tags = {
       Name = "Mysql-OS"
   }

}

resource "aws_instance" "WordPress-OS" {
  ami           = "ami-0487b1fe60c1fd1a2"
  instance_type = "t2.micro"
  key_key_name = "mynewkey"
  aassociate_public_ip_address = true
  subnet_id = aws_subnet.wpsn1.id  
  vpc_security_group_ids = [ aws_security_group.sg-mywp.id ]
  availability_zone = "us-west-1a"

   tags = {
       Name = "WordPress-OS"
   }

}

