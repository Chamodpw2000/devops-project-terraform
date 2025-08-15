# This Terraform block creates an AWS VPC (Virtual Private Cloud) resource.
# cidr_block = var.vpc_cidr:
# Sets the IP address range for the VPC, using the value from the variable vpc_cidr (e.g., "10.0.0.0/16").
# The IP address range for a VPC refers to the set of private IP addresses that resources (like EC2 instances, subnets)
# inside the VPC can use. This range is defined using a CIDR block (e.g., 10.0.0.0/16).

# Key Points:
# It determines the size and structure of your network within AWS.
# All subnets and resources in the VPC must use IPs within this range.
# You choose the range to avoid conflicts with other networks and to fit your needs.
# Example:
# If you set cidr_block = "10.0.0.0/16", your VPC can use IP addresses from 10.0.0.0 to 10.0.255.255.
# enable_dns_support = true:
# Enables DNS resolution within the VPC, allowing instances to resolve domain names.
# When enable_dns_support = true is set in an AWS VPC, it means that the VPC will have access to Amazon’s internal DNS server. This allows resources
# (like EC2 instances) inside the VPC to:

# Resolve domain names (e.g., www.google.com) to IP addresses.
# Use AWS internal DNS names to communicate with other AWS services (like S3, RDS, or other EC2 instances).
# Automatically resolve private DNS names for AWS resources (such as the private IP of an EC2 instance using its hostname).
# Why is this useful?

# You can use hostnames instead of IP addresses for communication between resources.
# Essential for services that require DNS, like Kubernetes, databases, and load balancers.
# Makes it easier to manage and scale resources, since you don’t need to hard-code IP addresses.
# Summary:
# It enables all resources in the VPC to use DNS for name resolution, making networking and service discovery much easier and more flexible.
# enable_dns_hostnames = true:
# Allows instances in the VPC to be assigned DNS hostnames.

# When you set enable_dns_hostnames = true in an AWS VPC, it means that any EC2 instance launched in that VPC will automatically get a DNS hostname assigned by AWS.

# What does this actually do?
# Automatic Hostnames: Every instance gets a DNS name like ip-10-0-0-1.ec2.internal.
# Internal Communication: Other resources in the VPC can use these hostnames to connect to instances, instead of using IP addresses.
# Public DNS (with public subnet): If the instance has a public IP, it also gets a public DNS name (e.g., ec2-54-123-45-67.compute-1.amazonaws.com), which can be used to access it from the internet.
# Required for AWS Services: Some AWS features (like Elastic Load Balancer, Route 53, or Kubernetes) rely on DNS hostnames for service discovery and communication.
# Why is this useful?
# Easier Management: You don’t need to remember or update IP addresses; hostnames stay consistent even if IPs change.
# Automation: Scripts and tools can use hostnames for dynamic environments.
# Integration: Many AWS services expect instances to have DNS hostnames for proper operation.

# Why use tags?

# Organization: Helps you sort and filter resources in the AWS console.
# Automation: Many AWS services and tools use tags for automation, billing, and access control.
# Integration: Required for some AWS features (like EKS, cost allocation, and resource grouping).

# You can fully customize the keys and values in the tags block for AWS resources. There is no strict predefined set—tags are just key-value pairs you define.

# However:

# Some AWS services (like EKS, cost allocation, or automation tools) expect specific tag keys for certain features to work (e.g., Name, kubernetes.io/cluster/...).
# For your own organization, you can use any keys and values that help you manage, organize, or automate your resources.

# Name Tag
# Purpose:
# Gives your VPC a human-readable name in the AWS console.
# Value:
# "${var.cluster_name}-vpc" combines the value of the cluster_name variable with -vpc.
# Example: If cluster_name is demo, the VPC name will be demo-vpc.
# Benefit:
# Makes it easier to identify and manage resources, especially in environments with many VPCs.
# kubernetes.io/cluster/${var.cluster_name} Tag
# Purpose:
# Used by Kubernetes (especially EKS) and AWS to identify which resources belong to a specific Kubernetes cluster.
# Value:
# "shared" means the resource can be used by multiple components in the cluster.
# Benefit:
# AWS and Kubernetes use this tag for automatic resource discovery, load balancer integration, and cluster management.

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.cluster_name}-vpc"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
}


# resource "aws_subnet" "private":
# Declares a subnet resource named private.

# count = length(var.private_subnet_cidrs):
# Creates as many subnets as there are CIDR blocks in the private_subnet_cidrs variable (one subnet per CIDR).

# vpc_id = aws_vpc.main.id:
# Associates each subnet with the VPC you created earlier.

# cidr_block = var.private_subnet_cidrs[count.index]:
# Assigns each subnet a unique IP range from the list in private_subnet_cidrs.

# availability_zone = var.availability_zones[count.index]:
# Places each subnet in a specific AWS Availability Zone for high availability.

# tags = { ... }:
# Adds metadata to each subnet:

# Name: Gives each subnet a unique name based on the cluster name and its index.
# "kubernetes.io/role/internal-elb" = "1": Tag used by Kubernetes to identify subnets for internal load balancers (private traffic only).

resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    
    tags = {
        Name = "${var.cluster_name}-private-subnet-${count.index + 1}"
        "kubernetes.io/role/internal-elb" = "1" 
    }
  
}

# map_public_ip_on_launch = true:
# Automatically assigns a public IP address to any EC2 instance launched in this subnet, 
# making it accessible from the internet.

# Public Subnet
# Purpose:
# Designed for resources that need direct access to the internet (e.g., web servers, load balancers).
# Key Differences:
# map_public_ip_on_launch = true:
# Automatically assigns a public IP to instances launched in this subnet, making them reachable
# from the internet.
# Tags:
# "kubernetes.io/role/elb" = "1": Marks the subnet for external load balancers (public-facing).
# "kubernetes.io/cluster/${var.cluster_name}" = "shared": Used for Kubernetes cluster identification.

# Internet Gateway:
# Public subnets are typically associated with a route table that directs traffic to an Internet Gateway.
# Private Subnet
# Purpose:
# Designed for resources that should not be directly accessible from the internet (e.g., databases, 
# internal services).

# Key Differences:
# No map_public_ip_on_launch:
# Instances do not get public IPs, so they cannot be reached directly from the internet.
# Tags:
# "kubernetes.io/role/internal-elb" = "1": Marks the subnet for internal load balancers 
# (private traffic only).
# No cluster identification tag (unless added separately).

# NAT Gateway:
# Private subnets typically use a NAT Gateway for outbound internet access (e.g., to download updates), but cannot receive inbound traffic from the internet.
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.cluster_name}-public-subnet-${count.index + 1}"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"
    }

}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.cluster_name}-igw"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
        }

        tags = {
        Name = "${var.cluster_name}-public"
        }
}

resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
    count = length(var.private_subnet_cidrs)
    domain = "vpc"
    
    tags = {
        Name = "${var.cluster_name}-nat-eip-${count.index + 1}"
    }
    
    depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "name" {
    count = length(var.private_subnet_cidrs)
    allocation_id = aws_eip.nat[count.index].id
    subnet_id = aws_subnet.public[count.index].id

    tags = {
        Name = "${var.cluster_name}-nat-${count.index + 1}"
    }
}

resource "aws_route_table" "private" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.name[count.index].id
    }
    tags = {
        Name = "${var.cluster_name}-private-${count.index + 1}"
    }
}

resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private[count.index].id
}







