provider "aws" {
    region = "us-west-2"
}

resource "aws_s3_bucket" "s3-bucket" {

bucket = "demo-terraform-eks-chamod-state-bucket-chamod"
lifecycle {
    prevent_destroy = false
} 
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
    name = "terraform-eks-state-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    
  
}

