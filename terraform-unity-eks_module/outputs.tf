output "eks" {
  description = "AWS EKS module object to output"
  value       = module.eks
}

output "cluster_iam_role" {
  description = "ARN of cluster iam role"
  value       = aws_iam_role.cluster_iam_role.name
}
