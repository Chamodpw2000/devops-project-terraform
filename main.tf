# This main.tf file is a Terraform configuration for deploying infrastructure on AWS, 
# specifically for an EKS (Elastic Kubernetes Service) cluster. Here’s a breakdown of its components:

# terraform block: Specifies the required provider (aws) and configures remote state storage using an S3 
# bucket and DynamoDB table for state locking and consistency.
# provider "aws": Sets the AWS region to us-west-2.
# module "vpc": Uses a local module (vpc) to create a VPC, subnets, and related networking resources. 
# It passes variables for CIDRs, availability zones, and cluster name.
# module "eks": Uses another local module (eks) to create the EKS cluster. It passes the cluster name, 
# version, VPC ID, subnet IDs, and node group configuration, referencing outputs from the VPC module.
# This file orchestrates the creation of a network (VPC) and an EKS cluster using reusable modules, 
# with state managed remotely for collaboration and safety.

# This block configures Terraform itself:

# required_providers: Specifies that the AWS provider (from HashiCorp) is required, and sets its version 
# to ~> 5.0 (any 5.x version).
# backend "s3": Configures remote state storage in an S3 bucket. 
# This means Terraform will store its state file (terraform.tfstate) in the specified S3 bucket, 
# under the given key. It also uses a DynamoDB table for state locking (to prevent concurrent changes) and 
# enables encryption for the state file. The region for both S3 and DynamoDB is set to us-west-2.
# This setup allows multiple users to safely collaborate on infrastructure changes, with state stored and 
# locked remotely.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "demo-terraform-eks-chamod-state-bucket-chamod-apsouth1-20250818"
    key = "terraform.tfstate"
    region  = "ap-south-1"
    dynamodb_table = "terraform-eks-state-locks" 
    encrypt = true
  }
}



provider "aws" {
  region = "ap-south-1"
}



module "vpc" {

  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr

#   variable "vpc_cidr" {
#   description = "CIDR block for VPC"
#   type        = string
#   default     = "10.0.0.0/16"
# }

availability_zones = var.availability_zones

# variable "availability_zones" {
#   description = "Availability zones"
#   type        = list(string)
#   default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
# }



  private_subnet_cidrs = var.private_subnet_cidrs

# variable "private_subnet_cidrs" {
#   description = "CIDR blocks for private subnets"
#   type        = list(string)
#   default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
# }

  public_subnet_cidrs = var.public_subnet_cidrs

# variable "public_subnet_cidrs" {
#   description = "CIDR blocks for public subnets"
#   type        = list(string)
#   default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
# }

  cluster_name = var.cluster_name

  # variable "cluster_name" {
  # description = "Name of the EKS cluster"
  # type        = string
  # default     = "my-eks-cluster"
# }
      
}

module "eks" {
  source = "./modules/eks"

  cluster_name = var.cluster_name

# variable "cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
#   default     = "my-eks-cluster"
# }

  cluster_version = var.cluster_version

# variable "cluster_version" {
#   description = "Kubernetes version"
#   type        = string
#   default     = "1.30"
# }


  vpc_id = module.vpc.vpc_id

# module.vpc.vpc_id  is a output from the vpc module

# output "vpc_id" {
#     description = "VPC ID"
#     value       = aws_vpc.main.id
# }



  subnet_ids = module.vpc.private_subnet_ids

#   output "private_subnet_ids" {
#     description = "Private Subnet IDs"
#     value       = aws_subnet.private[*].id
# }


  node_groups = var.node_groups

# variable "node_groups" {
#   description = "EKS node group configuration"
#   type = map(object({
#     instance_types = list(string)
#     capacity_type  = string
#     scaling_config = object({
#       desired_size = number
#       max_size     = number
#       min_size     = number
#     })
#   }))
#   default = {
#     general = {
#       instance_types = ["t3.micro"]
#       capacity_type  = "ON_DEMAND"
#       scaling_config = {
#         desired_size = 2
#         max_size     = 4
#         min_size     = 1
#       }
#     }
#   }
# }


}



