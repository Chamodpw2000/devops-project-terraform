//Provider block defines the cloud provider and region
provider "aws" {
    region = "ap-south-1"
}

# This Terraform block defines an AWS S3 bucket resource:
# resource "aws_s3_bucket" "s3-bucket":
# Declares a resource of type aws_s3_bucket and names it s3-bucket for 
# reference within Terraform.
# bucket = "demo-terraform-eks-chamod-state-bucket-chamod":
# Sets the name of the S3 bucket to demo-terraform-eks-chamod-state-bucket-chamod.
# lifecycle { prevent_destroy = false }:
# The lifecycle block controls how Terraform manages the resource.
# prevent_destroy = false means Terraform is allowed to destroy (delete) this bucket if you run terraform destroy or remove the resource from your configuration.
# If set to true, Terraform would refuse to destroy the bucket, protecting it from accidental deletion.
# This block creates an S3 bucket with a specific name and allows Terraform to delete it if needed. The lifecycle setting is useful for controlling resource protection.

resource "aws_s3_bucket" "s3-bucket" {

bucket = "demo-terraform-eks-chamod-state-bucket-chamod-apsouth1-20250818"
force_destroy = true
lifecycle {
    prevent_destroy = false
} 
}


# resource "aws_dynamodb_table" "basic-dynamodb-table":
# Declares a resource of type aws_dynamodb_table and names it basic-dynamodb-table for reference in Terraform.

# name = "terraform-eks-state-locks":
# Sets the name of the DynamoDB table to terraform-eks-state-locks.

# billing_mode = "PAY_PER_REQUEST":
# Configures the table to use on-demand billing, meaning you only pay for the read/write requests you make (no need to specify capacity units).

# hash_key = "LockID":
# Sets the primary key (partition key) for the table to the attribute named LockID.

# attribute { name = "LockID" type = "S" }:
# Defines the attribute LockID as a string (S). This is required because it’s used as the hash key.

resource "aws_dynamodb_table" "basic-dynamodb-table" {
    name = "terraform-eks-state-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    
  
}

# This table is typically used for state locking when using Terraform with a remote backend (like S3).
# It helps prevent multiple users from making changes to the state file at the same time by storing lock information
# in DynamoDB.


