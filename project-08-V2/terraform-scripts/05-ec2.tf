# Data source
# Get latest AMI ID for Amazon Linux2 OS
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


# bastion-server in public-subnet-1
resource "aws_instance" "wp-bastion-server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  key_name                    = "wp-project"
  subnet_id                   = aws_subnet.wp-public-subnet-1.id
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.wp-bastion-sg.id]
  #user_data                   = base64encode(local.user_data)
  #user_data = file("user-data.sh")      
  tags = {
    "Name" = "bastion-server"
  }
}


# two app-servers in private-subnets
resource "aws_instance" "wp-app-server-1" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  key_name                    = "wp-project"
  subnet_id                   = aws_subnet.wp-private-subnet-1.id
  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.wp-App-SG.id]
  #user_data                   = base64encode(local.user_data)
  #user_data = file("user-data.sh")      
  tags = {
    "Name" = "app-server-1"
  }
}

resource "aws_instance" "wp-app-server-2" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  key_name                    = "wp-project"
  subnet_id                   = aws_subnet.wp-private-subnet-2.id
  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.wp-App-SG.id]
  #user_data                   = base64encode(local.user_data)
  #user_data = file("user-data.sh")      
  tags = {
    "Name" = "app-server-2"
  }
}

