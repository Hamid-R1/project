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

