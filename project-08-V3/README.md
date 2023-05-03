## Project-3: Load balancer HTTPS Setup with Certificate Manager and Route53
- Here we will set up Load Balancer for HTTPS traffic with AWS Certificate Manager, and Route53
- We will also learn how to redirect HTTP traffic to HTTPS.



### AWS services for this demo
- ec2 Instance
- Target Group
- Load Balancer
- Route53
- AWS Certificate Manager (ACM)



### Step-01: Create two `ec2-instances` with these details:
- Name: `app-server-1`
- ami: `amazon-linux-2`
- Instance type: `t2.micro`
- Key pair: `wp-project` (select existing one)
- VPC: `default`
- security groups: `allow 22, 80 & 443 ports`
- user-data: `paste below scripts` & launch instance:
```
#!/bin/bash

# System Updates
sudo su
yum -y update

# Install Apache Web Server
yum install -y httpd

# Start & enable Apache Web Server
systemctl start httpd
systemctl enable httpd

# Install git & clone 'source-code' from github
yum install -y git
mkdir source-code
cd source-code
git clone https://github.com/Hamid-R1/basic_profile_website.git

# Configure & setup 'html_page' to this path '/var/www/html/'
cd basic_profile_website/html_page/
cp -r * /var/www/html/
```
	


### Step-02: create `target group` & `Application load-balancer`
- create `target group`:
```
- Choose a target type:  Instance
- Target group name:  app-target-group
- Protocol:  HTTP,		Port:  80
- VPC: default
- Healthy threshold:  3
- Unhealthy threshold:  2
- Timeout:  2
- Interval: 5
- Register targets: select both available instances & click on `Include as pending below`
- create target group.
```

- create `ALB`
```
- Load balancer types:  Application Load Balancer
- Load balancer name:  App-ALB
- Scheme: Internet-facing
- IP address type: IPv4
- VPC:  default
- Mappings:  
	- A.Z.:  ap-southeast-1a,
	- A.Z.:  ap-southeast-1b,
- Security groups:  existing (allow 80 & 443)
- Listeners and routing: 
	- Protocol: HTTP,     Port: 80,      Forward to: app-target-group
- create load balancer.
```




### Step-03: Create Record in `Amazon Route 53` for route traffic to Application load balancer:
- go to Route 53 >> Hosted zones >> cloud-ops.store >> Create record: here we need to create `A record`:
```
	- Record name: app
	- Record type: A – Routes traffic to an IPv4 address and some AWS resources
	- alias: enabled
	- Route traffic to: Alias to Application and Classic Load Balancer
	- choose region: Singapore  (ap-southeast-1)
	- choose load balncer: select-your-load-balancer
	- Routing policy: simple policy
	- Evaluate target health: yes/enabled
	- `create records` >> done.
```



### Step-04: Request a public SSL/TLS certificate from Amazon
- go to AWS Certificate Manager (ACM) >> Request certificate >> 
```
- Certificate type: Request a public certificate
- Fully qualified domain name: app.cloud-ops.store   or    dev.cloud-ops.store
- Validation method: DNS validation - recommended
- Key algorithm: RSA 2048
- Request >> 

- Next click on `certificate id` >> click on `create record in route53` >> create records >> done.
	- Next go to hosted zone & refresh, now you get one entry is there for `C Record` for DNS validation
```




### Step-05: Set up `Load Balancer` for `HTTPS` traffic with AWS `Certificate Manager`
- Add listener in existing `application-load-balancer` for `HTTPS` request
- go to existing load-balancer >> Listeners >> Add listener >>
```
- Protocol: HTTPS,		Port: 443
- Add action:  Forward to
	- Target group: App-TG
- Security policy: default one
- Default SSL/TLS certificate:
	- From ACM: select `app.cloud-ops.store`
- add >> done.
```





### Step-06: Redirect HTTP traffic to HTTPS
- go to existing load-balancer >> listener >> select `HTTP:80` >> manage rules
```
- delete existing rule and add action to `redirect to..`: 
	- HTTPS   Port: 443
- save & update.
```


#### ===========> Thank You <=================
