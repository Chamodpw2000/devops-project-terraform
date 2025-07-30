resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "${var.cluster_name}-vpc"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
}

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