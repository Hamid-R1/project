project-08-V2


# Project: Wordpress Application Deploy on AWS infrastructure & Build Website
- WordPress is a free and open-source `content management system` (CMS) software that is used to create websites, blogs, and online stores. It is one of the most popular CMS tools in the world, with over 40% of all websites on the internet built using WordPress.
- WordPress is written in `PHP` and uses a `MySQL` or `MariaDB` database to store content and settings. It is designed to be user-friendly, with a wide range of themes and plugins available to customize the appearance and functionality of a website.
- this is `monolithic` project, in our next version of this project we will move `monolithic` to `microservice` (Containerizing applications).


## AWS Infra Architecture for this project
- upload_here_image 


## AWS services for this project
- 1 vpc
- 6 subnets
- 3 route tables
- 1 Internet gateway
- 1 nat gateway
- 4 security groups
- 1 RDS-server
- 2 App-severs
- 1 ALB with target group
- 1 bastion-server



## Step-01: VPC Complete Network Creation in Singapore-Region (ap-southeast-1)
- 1 vpc
- 6 subnets (2 public subnets, 2 private subnets, 2 database subnets)
- 1 route table for public subnets
- 1 route table for private subnets
- 1 route table for database subnets
- 1 Internet gateway
- 1 nat gateway


### Step-01:01: Terraform script for VPC Complete Network Creation: `02-vpc.tf`
```t
# VPC
resource "aws_vpc" "wp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    "Name" = "pr8-vpc"
  }
}


######################################################################
# 6 subnets (2 public subnets, 2 private subnets, 2 database subnets)
######################################################################
# 2 public subnets
resource "aws_subnet" "wp-public-subnet-1" {
  vpc_id            = aws_vpc.wp_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "wp-public-subnet-2" {
  vpc_id            = aws_vpc.wp_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
  tags = {
    Name = "public-subnet-2"
  }
}


# 2 private subnets
resource "aws_subnet" "wp-private-subnet-1" {
  vpc_id            = aws_vpc.wp_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "wp-private-subnet-2" {
  vpc_id            = aws_vpc.wp_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-1b"
  tags = {
    Name = "private-subnet-2"
  }
}


# 2 database subnets
resource "aws_subnet" "wp-database-subnet-1" {
  vpc_id            = aws_vpc.wp_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "database-subnet-1"
  }
}

resource "aws_subnet" "wp-database-subnet-2" {
  vpc_id            = aws_vpc.wp_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "ap-southeast-1b"
  tags = {
    Name = "database-subnet-2"
  }
}



# Internet Gateway
resource "aws_internet_gateway" "wp_igw" {
  vpc_id = aws_vpc.wp_vpc.id
  tags = {
    "Name" = "pr8-igw"
  }
}



# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# Nat Gateway
resource "aws_nat_gateway" "wp-nat-gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.wp-public-subnet-1.id
  tags = {
    Name = "pr8-nat-gw"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.wp_igw]
}



######################################################
# public route table
# public subnets association into public route table
# Add Internet Gateway into public route table
######################################################
# public route table
resource "aws_route_table" "wp-public-rt" {
  vpc_id = aws_vpc.wp_vpc.id
  tags = {
    "Name" = "public-rt"
  }
}

# Associate both public subnets with public route table
resource "aws_route_table_association" "public_subnet_association-1" {
  route_table_id = aws_route_table.wp-public-rt.id
  subnet_id      = aws_subnet.wp-public-subnet-1.id
}

resource "aws_route_table_association" "public_subnet_association-2" {
  route_table_id = aws_route_table.wp-public-rt.id
  subnet_id      = aws_subnet.wp-public-subnet-2.id
}

# Add Internet Gateway into public route table
resource "aws_route" "wp-route-igw" {
  route_table_id         = aws_route_table.wp-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.wp_igw.id
}



######################################################
# private route table
# private subnets association into private route table
# Add Nat Gateway into private route table
######################################################
# private route table
resource "aws_route_table" "wp-private-rt" {
  vpc_id = aws_vpc.wp_vpc.id
  tags = {
    "Name" = "private-rt"
  }
}

# Associate both private subnets with private route table
resource "aws_route_table_association" "private_subnet_association-1" {
  route_table_id = aws_route_table.wp-private-rt.id
  subnet_id      = aws_subnet.wp-private-subnet-1.id
}

resource "aws_route_table_association" "private_subnet_association-2" {
  route_table_id = aws_route_table.wp-private-rt.id
  subnet_id      = aws_subnet.wp-private-subnet-2.id
}

# Add Nat Gateway into private route table
resource "aws_route" "wp-route-nat-gw" {
  route_table_id         = aws_route_table.wp-private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.wp-nat-gw.id
}



######################################################
# database route table
# database subnets association into database route table
######################################################
# database route table
resource "aws_route_table" "wp-database-rt" {
  vpc_id = aws_vpc.wp_vpc.id
  tags = {
    "Name" = "database-rt"
  }
}

# Associate both database subnets with database route table
resource "aws_route_table_association" "database_subnet_association-1" {
  route_table_id = aws_route_table.wp-database-rt.id
  subnet_id      = aws_subnet.wp-database-subnet-1.id
}

resource "aws_route_table_association" "database_subnet_association-2" {
  route_table_id = aws_route_table.wp-database-rt.id
  subnet_id      = aws_subnet.wp-database-subnet-2.id
}
```



## Step-02: create all security groups for all compute resources
- 1 security group for bastion-server
- 1 security group for pr8-alb(application-load-balancer)
- 1 security group for both app-servers
- 1 security group for rds-server
- upload_here security groups architecture


### Step-02:01: Terraform script for security groups: `03-security-group.tf`
```t
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
  ingress {
    description = "Allow port 443 from anywhere"
    from_port   = 443
    to_port     = 443
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
```




## Step-03: create rds instance with mysql engine
- create subnet-group for rds-server
- create rds-server with mysql engine


### Step-03:01: Terraform script for rds instance: `04-rds.tf`
```t
#############################
# DB Subnet Group creation
#############################
resource "aws_db_subnet_group" "db_sub_group" {
  name        = "db-subnet-group"
  description = "db-subnet-group-for-rds-server"
  subnet_ids  = [aws_subnet.wp-database-subnet-1.id, aws_subnet.wp-database-subnet-2.id]
  tags = {
    Name = "My-DB-subnet-group"
  }
}


#####################
# db_instance
#####################
resource "aws_db_instance" "db_instance" {
  identifier               = "rds-server"
  engine                   = "mysql"
  db_name                  = "HR_RDS_DB"
  username                 = "admin"
  password                 = "Project8"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  db_subnet_group_name     = aws_db_subnet_group.db_sub_group.id
  multi_az                 = false
  skip_final_snapshot      = true
  delete_automated_backups = true
  publicly_accessible      = false
  port                     = 3306
  vpc_security_group_ids   = [aws_security_group.wp-DB-SG.id]
}
```



## Step-04: Ec2-Instances
- create bastion-server in public-subnet-1
- create 2 ec2-instances(app-server-1 & app-server-2) in private-subnets


### Step-04:01: Terraform script for `Instance` creation: `05-ec2.tf`
```t
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
```



## Step-05: create Application load-balancer
- create target group
- create alb


### Step-05:01: Terraform script for `target group` & `Application load-balancer`: `06-alb.tf` 
```t
# target group
resource "aws_lb_target_group" "wp_tg" {
  target_type = "instance"
  name        = "pr8-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.wp_vpc.id

  stickiness { #here no need to enabled this stickiness argument,#
    #enabled = true
    enabled         = false
    type            = "lb_cookie"
    cookie_duration = 3600
  }

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
  }

}


# aws_lb_target_group_attachment 
resource "aws_lb_target_group_attachment" "instances-attachment-1" {
  target_group_arn = aws_lb_target_group.wp_tg.arn
  target_id        = aws_instance.wp-app-server-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instances-attachment-2" {
  target_group_arn = aws_lb_target_group.wp_tg.arn
  target_id        = aws_instance.wp-app-server-2.id
  port             = 80
}


# ALP
resource "aws_lb" "wp_alb" {
  name                       = "pr8-alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = [aws_subnet.wp-public-subnet-1.id, aws_subnet.wp-public-subnet-2.id]
  security_groups            = [aws_security_group.wp-ALB-SG.id]
  enable_deletion_protection = false
  /* "enable_deletion_protection" If true, deletion of the load balancer will be disabled via 
  the AWS API. This will prevent Terraform from deleting the load balancer.*/
}


# Load Balancer Listener
resource "aws_lb_listener" "alb_forward_listener" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}


/*
# Load Balancer Listener (on SSL 443 'https')
resource "aws_lb_listener" "front_end-443" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}
*/
```



## Step-06: Create All Above AWS Services byusing Terraform CLI
```t
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```



## Step-07: Deploy application and configure to make available for end-users
- ssh `bastion-server` 
- copy `wp-project.pem` file from local pc to `bastion-server` & give read permission 
```bash
vim wp-project
chmod 400 wp-project
```

- ssh to `app-server-1` from `bastion-server`
```bash
ssh -i "wp-project" ec2-user@private-ip-of-app-server-1
```


### Step-07-01: Install dependencies, system softwares, application & configure application files in `app-server-1`
```bash
vim deploy-app.sh

# run shell file `deploy-app.sh`
bash deploy-app.sh

# come back to bastion-server
exit
```

- `cat deploy-app.sh` see shell scrips:
```
#!/bin/bash -xe

# System Updates
sudo yum -y update


# STEP 1 - Install system software - including Web and DB
sudo yum install -y mariadb-server httpd
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2


# STEP 2 - Web and DB Servers Online - and set to startup
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl start mariadb
sudo systemctl enable mariadb


# STEP 3 - Setpassword & DB Variables
DBName='HR_RDS_DB'
DBUser='admin'
DBPassword='Project8'
DBRootPassword='Admin123root'
DBEndpoint='copy_here_rds_endpoint'


# STEP 4 - Set Mariadb Root Password
mysqladmin -u root password $DBRootPassword


# STEP 5 - Install Wordpress
sudo wget http://wordpress.org/latest.tar.gz -P /var/www/html
cd /var/www/html
sudo tar -zxvf latest.tar.gz
sudo cp -rvf wordpress/* .
sudo rm -R wordpress
sudo rm latest.tar.gz


# STEP 6 - Configure Wordpress
sudo cp ./wp-config-sample.php ./wp-config.php
sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
sudo sed -i "s/'localhost'/'$DBEndpoint'/g" wp-config.php

# Step 6a - permissions 
sudo usermod -a -G apache ec2-user    #Add your user (in this case, ec2-user) to the apache group. 
sudo chown -R ec2-user:apache /var/www    #Change the group ownership of /var/www and its contents to the apache group.
sudo chmod 2775 /var/www

sudo find /var/www -type d -exec chmod 2775 {} \;
sudo find /var/www -type f -exec chmod 0664 {} \;

# STEP 7 Create Wordpress DB
echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
mysql -u root --password=$DBRootPassword < /tmp/db.setup
sudo rm /tmp/db.setup
```




### Step-07-02: Install dependencies, system softwares, application & configure application files in `app-server-1`
```bash
#ssh to app-server-2 from bastion-server
ssh -i "wp-project" ec2-user@private-ip-of-app-server-2

# create & copy same shell scrips file `deploy-app.sh` which we created in `Step-07-01`
vim deploy-app.sh

# run shell file `deploy-app.sh`
bash deploy-app.sh
```




## Step-08: Configuring `Amazon Route 53` to route traffic to Application load balancer:
- go to AWS Console: >> Route 53 >> Hosted zones >> cloud-ops.store >> Create record: here we need to create 2 records:
	- Record 1:
		- Record name: ---
		- Record type: A – Routes traffic to an IPv4 address and some AWS resources
		- alias: enabled
		- Route traffic to: Alias to Application and Classic Load Balancer
		- choose region: Singapore  (ap-southeast-1)
		- choose load balncer: select-your-load-balancer
		- Routing policy: simple policy
		- Evaluate target health: yes/enabled
		- clik on `create records` >> done.
	
	- Record 2:
		- Record name: www
		- Record type: A – Routes traffic to an IPv4 address and some AWS resources
		- alias: enabled
		- Route traffic to: Alias to Application and Classic Load Balancer
		- choose region: Singapore  (ap-southeast-1)
		- choose load balncer: select-your-load-balancer
		- Routing policy: simple policy
		- Evaluate target health: yes/enabled
		- clik on `create records` >> done.

	-Record 3:
		```
		- Record name: www
		- Record type: A – Routes traffic to an IPv4 address and some AWS resources
		- alias: enabled
		- Route traffic to: Alias to Application and Classic Load Balancer
		- choose region: Singapore  (ap-southeast-1)
		- choose load balncer: select-your-load-balancer
		- Routing policy: simple policy
		- Evaluate target health: yes/enabled
		- clik on `create records` >> done.
		```



## Step-09: Open `cloud-ops.store` domain & configure your application
- open this domain `cloud-ops.store` in new tab
- setup username & password for application & install
- login application dashboard & go through the dashboard
- open website which will be publicly available for end-users


##### =================> Thank You <=========================
