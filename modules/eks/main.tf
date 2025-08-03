resource "aws_iam_role" "cluster" {
  name = "cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }

      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}


resource "aws_eks_cluster" "main" {
    name = var.cluster.name
    version = var.cluster.version
    role_arn = aws_iam_role.cluster.arn

    vpc_config {
        subnet_ids = var.subnet_ids
     
    }

    depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}



  
