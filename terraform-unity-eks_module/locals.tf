locals {
  common_tags  = {}
  cluster_name = var.deployment_name
  subnet_map   = jsondecode(data.aws_ssm_parameter.subnet_list.value)
  #ami = "ami-0e3e9697a56f6ba66"
  ami_map = {
    "1.27"    = data.aws_ssm_parameter.eks_ami_1_27.value
    "1.26"    = data.aws_ssm_parameter.eks_ami_1_26.value
    "1.25"    = data.aws_ssm_parameter.eks_ami_1_25.value
    "default" = "ami-0e3e9697a56f6ba66"
  }
  #iam_arn = data.aws_ssm_parameter.eks_iam_node_role.value
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
      disk_size = ng.disk_size
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp2"
            encrypted             = true
            kms_key_id            = data.aws_ebs_default_kms_key.current.key_arn
            delete_on_termination = true
          }
        }
      }
    }
  }
  openidc_provider_domain_name = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
}
