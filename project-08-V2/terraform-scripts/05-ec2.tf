# Data source:  Get latest AMI ID for Amazon Linux2 OS
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



# Local variables
locals {
  user_data = <<-EOT
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
DBEndpoint='${aws_db_instance.db_instance.address}'

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
EOT
}



# bastion-server in public-subnet-1
resource "aws_instance" "wp-bastion-server" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  key_name                    = "wp-project"
  subnet_id                   = aws_subnet.wp-public-subnet-1.id
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.wp-bastion-sg.id]
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
  user_data                   = base64encode(local.user_data)
  #user_data = file("deploy-app.sh")
  tags = {
    "Name" = "app-server-1"
  }
  depends_on = [
    aws_db_instance.db_instance
  ]
}


resource "aws_instance" "wp-app-server-2" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  key_name                    = "wp-project"
  subnet_id                   = aws_subnet.wp-private-subnet-2.id
  associate_public_ip_address = "false"
  vpc_security_group_ids      = [aws_security_group.wp-App-SG.id]
  user_data                   = base64encode(local.user_data)
  #user_data = file("deploy-app.sh")
  tags = {
    "Name" = "app-server-2"
  }
  depends_on = [
    aws_db_instance.db_instance
  ]
}
