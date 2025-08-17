output "vpc_id" {
    description = "VPC ID"
    value       = aws_vpc.main.id
}

output "private_subnet_ids" {
    description = "Private Subnet IDs"
    value       = aws_subnet.private[*].id
}
output "public_subnet_ids" {
    description = "Public Subnet IDs"
    value       = aws_subnet.public[*].id
}

# These outputs are generated after Terraform applies your configuration and creates the resources.

# How it works:

# When you run terraform apply, Terraform provisions the VPC, subnets, and other resources.
# Each resource (like aws_vpc.main or aws_subnet.private) gets a unique ID from AWS.
# The output blocks collect these IDs and make them available for use outside the module 
# (e.g., in other modules or as command-line output).
# You can access these outputs using terraform output or by referencing them in other Terraform modules.

# In summary:
# These outputs provide the IDs of the created VPC and subnets, making it easy to use them elsewhere 
# in your infrastructure code.


# output "vpc_id":
# Returns the unique ID of the VPC created by your module. Other modules or resources 
#can use this ID to reference the VPC.

# output "private_subnet_ids":
# Returns a list of IDs for all private subnets created. Useful for launching resources 
# (like EC2 instances or RDS databases) in private subnets.

# output "public_subnet_ids":
# Returns a list of IDs for all public subnets created. Useful for resources that need 
# internet access, such as load balancers or public EC2 instances.

