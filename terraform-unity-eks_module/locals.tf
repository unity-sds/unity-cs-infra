locals {
  common_tags  = {}
  cluster_name = var.deployment_name
  subnet_map   = jsondecode(data.aws_ssm_parameter.subnet_list.value)
  ami_map = {
    "1.32"    = data.aws_ssm_parameter.eks_ami_1_32.value
    "1.31"    = data.aws_ssm_parameter.eks_ami_1_31.value
    "1.30"    = data.aws_ssm_parameter.eks_ami_1_30.value
    "default" = "ami-0741828961a03a9db"
  }
  mergednodegroups = { for name, ng in var.nodegroups :
    name => {
      use_name_prefix            = false
      create_iam_role            = false
      min_size                   = ng.min_size != null ? ng.min_size : 1
      max_size                   = ng.max_size != null ? ng.max_size : 10
      desired_size               = ng.desired_size != null ? ng.desired_size : 3
      ami_id                     = ng.ami_id != null ? ng.ami_id : lookup(local.ami_map, var.cluster_version, local.ami_map["default"])
      instance_types             = ng.instance_types != null ? ng.instance_types : ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
      capacity_type              = ng.capacity_type != null ? ng.capacity_type : "ON_DEMAND"
      iam_role_arn               = ng.iam_role_arn != null ? ng.iam_role_arn : aws_iam_role.cluster_iam_role.arn
      enable_bootstrap_user_data = true
      pre_bootstrap_user_data    = <<-EOT
            sudo sed -i 's/^net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf && sudo sysctl -p |true
        EOT
      metadata_options = {
        "http_endpoint" : ng.metadata_options != null ? lookup(ng.metadata_options, "http_endpoint", null) : null
        "http_put_response_hop_limit" : ng.metadata_options != null ? lookup(ng.metadata_options, "http_put_response_hop_limit", null) : null
        "http_tokens" : ng.metadata_options != null ? lookup(ng.metadata_options, "http_tokens", null) : null
      }
      tags = merge(local.common_tags, {
        Name      = "${local.cluster_name} Node Group Node"
        Component = "EKS EC2 Instance"
        Stack     = "EKS EC2 Instance"
      })
      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
          
            ---
            apiVersion: node.eks.aws/v1alpha
            kind: NodeConfig
            spec:
              cluster:
                name: ${local.cluster_name}
              kubelet:
                config:
                  shutdownGracePeriod: 30s
                  featureGates:
                    DisableKubeletCloudCredentialProviders: true
            EOT
        }
      ]
      block_device_mappings = ng.block_device_mappings != null ? { for device_name, mapping in ng.block_device_mappings :
        device_name => {
          device_name = mapping.device_name
          ebs = {
            volume_size           = mapping.ebs.volume_size
            volume_type           = mapping.ebs.volume_type
            encrypted             = mapping.ebs.encrypted
            kms_key_id            = data.aws_kms_key.current.arn
            delete_on_termination = mapping.ebs.delete_on_termination
          }
        }
      } : {}
    }
  }
  openidc_provider_domain_name = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
}
