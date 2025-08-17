# resource "aws_iam_role" "cluster": Declares a new IAM role named "cluster-role".
# assume_role_policy: Defines a trust policy that allows the EKS service (eks.amazonaws.com) to assume this role.
# Action = "sts:AssumeRole": Grants permission to assume the role.
# Effect = "Allow": Allows the action.
# Principal = { Service = "eks.amazonaws.com" }: Specifies that the EKS service can assume the role.

# Purpose: This role is required for the EKS control plane to manage AWS resources on your behalf, 
# such as networking, scaling, and node management. It is referenced by your EKS cluster resource as role_arn.
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

# This Terraform block attaches the AmazonEKSClusterPolicy IAM policy to your EKS cluster role:

# policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy": Specifies the AWS-managed policy 
# that grants permissions needed for EKS cluster operations (like managing networking, nodes, and 
# other AWS resources).
# role = aws_iam_role.cluster.name: Specifies the IAM role (created earlier) that will receive these 
# permissions.
# Purpose: This ensures your EKS cluster control plane has the necessary permissions to manage 
# resources in your AWS account. Without this attachment, the cluster would not function properly.


resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}




# This Terraform block creates your main EKS (Elastic Kubernetes Service) cluster:

# name = var.cluster_name: Sets the cluster's name from a variable.
# version = var.cluster_version: Specifies the Kubernetes version to use.
# role_arn = aws_iam_role.cluster.arn: Assigns the IAM role that EKS uses to manage AWS resources.
# vpc_config { subnet_ids = var.subnet_ids }: Defines which subnets the cluster will use for networking.
# depends_on = [aws_iam_role_policy_attachment.cluster_policy]: Ensures the IAM role and its policy 
# are attached before creating the cluster.
# Purpose: This resource provisions the EKS control plane, enabling you to run and manage Kubernetes 
# workloads in the specified VPC subnets with the required permissions.

resource "aws_eks_cluster" "main" {
    name = var.cluster_name
    version = var.cluster_version
    role_arn = aws_iam_role.cluster.arn

    vpc_config {
        subnet_ids = var.subnet_ids
     
    }

    depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}


resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# This Terraform block attaches multiple IAM policies to the EKS node IAM role:

# for_each = toset([...]): Iterates over a set of policy ARNs, so each policy is attached separately.
# policy_arn = each.value: The ARN of the policy being attached (e.g., worker node, CNI, and container 
# registry policies).
# role = aws_iam_role.node.name: The IAM role for EKS worker nodes that receives these permissions.
# Purpose: This ensures your EKS worker nodes have all the necessary permissions to join the cluster, 
# manage networking, and pull container images from Amazon ECR. Each policy provides a specific set of 
# permissions required for node operation in EKS.

# Here’s what each IAM policy does for EKS worker nodes:

# AmazonEKSWorkerNodePolicy

# Grants permissions for EC2 instances (worker nodes) to communicate with the EKS control plane.
# Allows nodes to join the cluster, register themselves, and report status.
# AmazonEKS_CNI_Policy

# Provides permissions for the Amazon VPC CNI plugin, which manages pod networking in EKS.
# Allows worker nodes to create, attach, and manage network interfaces for Kubernetes pods.
# AmazonEC2ContainerRegistryReadOnly

# Allows worker nodes to pull container images from Amazon Elastic Container Registry (ECR).
# Ensures nodes can download application images needed to run your workloads.
# Each policy is essential for proper operation of EKS worker nodes in your cluster.

resource "aws_iam_role_policy_attachment" "node_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  policy_arn = each.value
  role       = aws_iam_role.node.name

}

# This Terraform block creates managed node groups for your EKS cluster:

# for_each = var.node_groups: Creates a node group for each entry in the node_groups variable, 
# allowing multiple groups with different settings.
# cluster_name = aws_eks_cluster.main.name: Associates the node group with your EKS cluster.
# node_group_name = each.key: Sets the name for each node group.
# node_role_arn = aws_iam_role.node.arn: Assigns the IAM role for the worker nodes, giving them 
# necessary permissions.
# subnet_ids = var.subnet_ids: Specifies which subnets the nodes will be launched in.
# instance_types = each.value.instance_types: Defines the EC2 instance types for the nodes.
# capacity_type = each.value.capacity_type: Sets whether nodes are On-Demand or Spot instances.
# scaling_config: Configures desired, minimum, and maximum number of nodes for auto-scaling.
# depends_on = [aws_iam_role_policy_attachment.node_policy]: Ensures IAM policies are attached 
# before creating the node group.

# Purpose: This resource provisions and manages EC2 worker nodes for your Kubernetes workloads, 
# handling scaling, updates, and integration with the EKS control plane. Each node group can 
# have its own configuration for flexibility.



resource "aws_eks_node_group" "main"{
  for_each = var.node_groups
  cluster_name = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn = aws_iam_role.node.arn
  subnet_ids = var.subnet_ids
  instance_types = each.value.instance_types
  capacity_type = each.value.capacity_type
  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }
  depends_on = [ 
    aws_iam_role_policy_attachment.node_policy 
   ]
}







  
