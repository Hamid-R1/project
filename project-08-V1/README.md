# Project: Wordpress Application Deploy on AWS infrastructure & Build Website
- WordPress is a free and open-source `content management system` (CMS) software that is used to create websites, blogs, and online stores. It is one of the most popular CMS tools in the world, with over 40% of all websites on the internet built using WordPress.
- WordPress is written in `PHP` and uses a `MySQL` or `MariaDB` database to store content and settings. It is designed to be user-friendly, with a wide range of themes and plugins available to customize the appearance and functionality of a website.
- this is `monolithic` project, in our next version of this project we will move `monolithic` to `microservice` (Containerizing applications).




## AWS Infra Architecture for this project
![Untitled Diagram drawio (26)](https://user-images.githubusercontent.com/112654341/222944548-3ee35638-451b-4dc9-ac2a-860401d6695c.png)

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



## Step-A: VPC Complete Network Creation in Singapore-Region (ap-southeast-1)
- 1 vpc
- 6 subnets (2 public subnets, 2 private subnets, 2 database subnets)
- 1 route table for public subnets
- 1 route table for private subnets
- 1 route table for database subnets
- 1 Internet gateway
- 1 nat gateway


### Step-A-01: create vpc in Singapore-Region
- Name tag: pr8-vpc
- IPv4 CIDR: 10.0.0.0/16


### Step-A-02: create 6 subnets (2 public subnets, 2 private subnets, 2 database subnets)
- create 2 public subnets with these details:
	- VPC: pr8-vpc
	- Subnet name: public-subnet-1
	- Availability Zone: ap-southeast-1a
	- IPv4 CIDR block: 10.0.1.0/24
	-
	- Subnet name: public-subnet-2
	- Availability Zone: ap-southeast-1b
	- IPv4 CIDR block: 10.0.2.0/24
	
- create 2 private subnets with these details:
	- VPC: pr8-vpc
	- Subnet name: private-subnet-1
	- Availability Zone: ap-southeast-1a
	- IPv4 CIDR block: 10.0.3.0/24
	-
	- Subnet name: private-subnet-2
	- Availability Zone: ap-southeast-1b
	- IPv4 CIDR block: 10.0.4.0/24
	
- create 2 database subnets with these details:
	- VPC: pr8-vpc
	- Subnet name: database-subnet-1
	- Availability Zone: ap-southeast-1a
	- IPv4 CIDR block: 10.0.5.0/24
	-
	- Subnet name: database-subnet-2
	- Availability Zone: ap-southeast-1b
	- IPv4 CIDR block: 10.0.6.0/24


### Step-A-03: create 3 route tables 
- 1 route table for public subnets & attach both public subnets into this route table
	- Name: public-rt
	- VPC: pr8-vpc
	-
	- public-rt >> Subnet associations >> select public-subnet-1 & public-subnet-2 and >> save.

- 1 route table for private subnets & attach both private subnets into this route table
	- Name: private-rt
	- VPC: pr8-vpc
	-
	- private-rt >> Subnet associations >> select private-subnet-1 & private-subnet-2 and >> save.

- 1 route table for database subnets & attach both database subnets into this route table
	- Name: database-rt
	- VPC: pr8-vpc
	-
	- database-rt >> Subnet associations >> select database-subnet-1 & database-subnet-2 and >> save.



### Step-A-04: create 1 Internet gateway & add this `pr8-igw` into `public-rt`
- Name: pr8-igw
- create
- attach to `pr8-vpc`
- 
- public-rt >> Routes >> edit route >> add `pr8-igw` >> save.
	- 0.0.0.0/0		pr8-igw


### Step-A-05: create 1 nat gateway in `public-subnet-1` & attach this `pr8-nat-gw` into `private-rt`
- Name: pr8-nat-gw
- Subnet: public-subnet-1
- Connectivity type: public
- Elastic IP allocation ID: allocate elastic ip & select
- create.
- 
- private-rt >> Routes >> edit route >> add `pr8-nat-gw` >> save.
	- 0.0.0.0/0		pr8-nat-gw




## Step-B: create all security groups for all compute resources
- 1 security group for bastion-server
- 1 security group for pr8-alb(application-load-balancer)
- 1 security group for app-servers
- 1 security group for rds-server

### security groups for all compute resources
![Untitled Diagram drawio (23)](https://user-images.githubusercontent.com/112654341/222944563-950b60ae-487c-477c-bd60-0a9d4ff8420e.png)


### Step-B-01: create 1 security group for bastion-server
- Security group name: bastion-sg
- Description: Allow port 22 from anywhere
- VPC: pr8-vpc
- add rule:
	- ssh,	22,		anywhere,	Description: Allow port 22 from anywhere
- tags: sg-for-bastion-server
- create


### Step-B-02: create 1 security group for ALB
- Security group name: ALB-SG
- Description: Allow port 80 from anywhere
- VPC: pr8-vpc
- add rule:
	- http,	80,	anywhere,		Description: Allow port 80 from anywhere
- tags: sg-for-pr8-alb
- create


### Step-B-03: create 1 security group for app-servers
- Security group name: App-SG
- Description: Allow port 22 from bastion-sg and 80 from ALB-SG
- VPC: pr8-vpc
- add rule:
	- ssh,	22, 	select-bastion-sg,		Description: allow-trrafic-from-bastion-sg-only
	- http,	80,		select-ALB-SG,			Description: allow-trrafic-from-ALB-SG-only
- tags: sg-for-app-servers
- create


### Step-B-04: create 1 security group for RDS-server
- Security group name: DB-SG
- Description: Allow port 3306 from App-SG only
- VPC: pr8-vpc
- add rule:
	- mysql,	3306,	select-App-SG,		Description: allow-trrafic-from-App-SG-only
- tags: sg-for-RDS-server
- create




## Step-C: create rds instance with mysql engine
- create subnet-group for rds-server
- create rds-server with mysql engine
- `aws official documents` reference: 
	- https://aws.amazon.com/getting-started/hands-on/deploy-wordpress-with-amazon-rds/module-one/


### Step-C-01: create subnet-group for rds-server
- Name: db-subnet-group
- Description: db-subnet-group-for-rds-server
- VPC: pr8-vpc
- Availability Zones: 
	- ap-southeast-1a:	database-subnet-1(10.0.5.0/24)
	- ap-southeast-1b:	database-subnet-2(10.0.6.0/24)
- create.



### Step-C-02: create rds-server with mysql engine
- Choose a database creation method:  Standard create
- Engine type:  MySQL
- Templates:  Free tier
- DB instance identifier:  rds-server
- Master username:  admin
- Master password:  Project8
- DB instance class:  db.t3.micro
- Storage type:  gp2
- Allocated storage:  20GB
- Storage autoscaling:  disable
-
- Compute resource:  Don’t connect to an EC2 compute resource
- Network type:  IPv4
- Virtual private cloud (VPC):  pr8-vpc
- DB subnet group:  db-subnet-group
- Public access:  No
- VPC security group (firewall):  DB-SG
- Availability Zone:  ap-southeast-1a
- Database port:  3306
- Database authentication options:  Password authentication
- Initial database name:  HR_RDS_DB
- Rest things:  default
- create database.




## Step-D: create 2 ec2-instances in private-subnets
- launch 1 ec2-instance in `private-subnet-1`
	- Name:  app-server-1
	- ami:  amazon-linux-2
	- Instance type:  t2.micro
	- Key pair:  wp-project (select existing one)
	- VPC:  pr8-vpc
	- subnet:  private-subnet-1
	- Auto-assign public IP:  Disable
	- Firewall (security groups) :  App-SG (select existing one)
	- launch instance.
-
- launch 1 ec2-instance in `private-subnet-2`
	- Name:  app-server-2
	- ami:  amazon-linux-2
	- Instance type:  t2.micro
	- Key pair:  wp-project (select existing one)
	- VPC:  pr8-vpc
	- subnet:  private-subnet-2
	- Auto-assign public IP:  Disable
	- Firewall (security groups) :  App-SG (select existing one)
	- launch instance.




## Step-E: create bastion-server in public-subnet-1
- Name:  bastion-server
- ami:  amazon-linux-2
- Instance type:  t2.micro
- Key pair:  wp-project (select existing one)
- VPC:  pr8-vpc
- subnet:  public-subnet-1
- Auto-assign public IP:  Enable
- Firewall (security groups) :  bastion-sg (select existing one)
- launch instance.




## Step-F: create Application load-balancer
- create target group
- create alb


### Step-F-01: create target group
- Choose a target type:  Instance
- Target group name:  pr8-target-group
- Protocol:  HTTP,		Port:  80
- VPC:  pr8-vpc
- 
- Healthy threshold:  3
- Unhealthy threshold:  2
- Timeout:  2
- Interval: 5
-
- Register targets: select both available instances & click on `Include as pending below`
- create target group.


### Step-F-02: create alb
- Load balancer types:  Application Load Balancer
- Load balancer name:  pr8-alb
- Scheme: Internet-facing
- IP address type: IPv4
- VPC:  pr8-vpc
- Mappings:  
	- A.Z.:  ap-southeast-1a,		Subnet:  public-subnet-1
	- A.Z.:  ap-southeast-1b,		Subnet:  public-subnet-2
- Security groups:  ALB-SG
- Listeners and routing: 
	- Protocol: HTTP,     Port: 80,      Forward to: pr8-target-group
- create load balancer.




## Step-G: Deploy application and configure to make available for end-users
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


### Step-G-01: Install dependencies, system softwares, application & configure application files in `app-server-1`
- `aws official documents` reference: 
	- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-lamp-amazon-linux-2.html
	- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/hosting-wordpress.html
```bash
vim deploy-app.sh

# see shell scrips of `deploy-app.sh`
cat deploy-app.sh
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



# run shell file `deploy-app.sh`
bash deploy-app.sh


# come back to bastion-server
exit
```




### Step-G-02: Install dependencies, system softwares, application & configure application files in `app-server-2`
```bash
#ssh to app-server-2 from bastion-server
ssh -i "wp-project" ec2-user@private-ip-of-app-server-2

# create & copy same shell scrips file `deploy-app.sh` which we created in `Step-G-01`
vim deploy-app.sh

# run shell file `deploy-app.sh`
bash deploy-app.sh
```




## Step-H: Open `pr8-alb` dns name & configure your application
- copy `DNS name` of `pr8-alb` and paste to new tab
- setup username & password for application & install
- login application dashboard & go through the dashboard
- open website which will be publicly available for end-users


### ================= Thank You =========================

