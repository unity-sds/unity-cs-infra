provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "Nightly"
      ServiceArea = "cs"
    }
  }
}

locals {
  common_tags = {}
  subnet_regex = "subnet-[0-9a-f]{17}"
}

resource "aws_eks_cluster" "eks_cluster" {
  name = var.cluster_name
  role_arn = data.aws_ssm_parameter.eks_service_role_arn.value
  version = "1.24"
  vpc_config {
    subnet_ids = [regex(local.subnet_regex, data.aws_ssm_parameter.eks_subnet_public_a.value),
                  regex(local.subnet_regex, data.aws_ssm_parameter.eks_subnet_public_b.value),
                  regex(local.subnet_regex, data.aws_ssm_parameter.eks_subnet_private_a.value),
                  regex(local.subnet_regex, data.aws_ssm_parameter.eks_subnet_private_b.value)]
  }
}

resource "null_resource" "iam_identity_mapping" {
  for_each = nonsensitive(toset(split(",", data.aws_ssm_parameter.eks_user_role_arn.value)))
  provisioner "local-exec" {
    command = <<EOT
    eksctl create iamidentitymapping \
    --cluster ${var.cluster_name} --region=${var.region} \
    --arn ${each.key} --group system:masters --username admin
    EOT
  }
  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_eks_node_group" "node_groups" {
  for_each = var.node_groups
  cluster_name = aws_eks_cluster.eks_cluster.name
  node_group_name = each.key
  node_role_arn = data.aws_ssm_parameter.eks_node_role_arn.value
  subnet_ids = [regex(local.subnet_regex, data.aws_ssm_parameter.eks_subnet_public_a.value),
                regex(local.subnet_regex, data.aws_ssm_parameter.eks_subnet_public_b.value)]
  
  launch_template {
    id = aws_launch_template.node_group_launch_template.id    
    version = aws_launch_template.node_group_launch_template.latest_version
  }

  instance_types = toset([each.value["instance_type"]])

  scaling_config {
    desired_size = each.value["node_count"]
    max_size = each.value["node_count"]
    min_size = each.value["node_count"]
  }

}

resource "aws_launch_template" "node_group_launch_template" {
  image_id = data.aws_ssm_parameter.eks_cluster_ami.value
  name = "eks-${var.cluster_name}-nodeGroup-launchTemplate"
  user_data = base64encode(<<EOT
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name}
  EOT
  )
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name      = "${var.cluster_name} Node Group Node"
      Component = "EKS EC2 Instance"
      Stack     = "EKS EC2 Instance"
    })
  }
}

# TODO: select default node group more intelligently, or remove concept altogether
resource "aws_ssm_parameter" "node_group_default_name" {
  name = "/unity/extensions/eks/${var.cluster_name}/nodeGroups/default/name"
  type = "String"
  # Get name of first nodegroup in nodegroup map variable
  value = keys(var.node_groups)[0]
  # Get first nodegroup name from keys of node group variable and use it to 
  # value = split(":", aws_eks_node_group.node_groups[keys(var.node_groups)[0]].id)[0]
}

resource "aws_ssm_parameter" "node_group_default_launch_template_name" {
  name = "/unity/extensions/eks/${var.cluster_name}/nodeGroups/default/launchTemplateName"
  type = "String"
  value = aws_launch_template.node_group_launch_template.name
}

resource "aws_ssm_parameter" "eks_subnets_private" {
  name = "/unity/extensions/eks/${var.cluster_name}/networking/subnets/privateIds"
  type = "String"
  value = data.aws_ssm_parameter.eks_subnets_private.value
}
