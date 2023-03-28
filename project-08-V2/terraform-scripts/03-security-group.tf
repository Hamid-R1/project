#####################################
# security group for bastion-server
#####################################
resource "aws_security_group" "wp-bastion-sg" {
  name        = "bastion-sg"
  description = "Allow port 22 from anywhere"
  vpc_id      = aws_vpc.wp_vpc.id
  tags = {
    "Name" = "sg-for-bastion-server"
  }
  ingress {
    description = "Allow port 22 from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


############################
# security group for ALB
############################
resource "aws_security_group" "wp-ALB-SG" {
  name        = "ALB-SG"
  description = "Allow port 80 and 443 from anywhere"
  vpc_id      = aws_vpc.wp_vpc.id
  tags = {
    "Name" = "sg-for-pr8-alb"
  }
  ingress {
    description = "Allow port 80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  /*
  ingress {
    description = "Allow port 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  */
  egress {
    description = "Allow All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


###################################
# security group for app-servers
###################################
resource "aws_security_group" "wp-App-SG" {
  name        = "App-SG"
  description = "Allow port 22 from bastion-sg and 80 from ALB-SG"
  vpc_id      = aws_vpc.wp_vpc.id
  tags = {
    "Name" = "sg-for-app-servers"
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.wp-bastion-sg.id]
    description     = "allow-trrafic-from-bastion-sg-only"
  }
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.wp-ALB-SG.id]
    description     = "allow-trrafic-from-ALB-SG-only"
  }
  /*
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.wp-ALB-SG.id]
    description     = "allow-trrafic-from-ALB-SG-only"
  }
  */
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow All"
  }
}


###################################
# security group for RDS-server
###################################
resource "aws_security_group" "wp-DB-SG" {
  name        = "DB-SG"
  description = "Allow port 3306 from App-SG only"
  vpc_id      = aws_vpc.wp_vpc.id
  tags = {
    "Name" = "sg-for-RDS-server"
  }
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wp-App-SG.id]
    description     = "allow-trrafic-from-App-SG-only"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow All"
  }
}
