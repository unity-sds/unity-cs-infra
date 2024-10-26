provider "aws" {
  region = var.region
  profile = var.profile

  default_tags {
    tags = var.common_tags
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/unity/account/network/vpc_id"
}
 
data "aws_ssm_parameter" "subnet_list" {
  name = "/unity/account/network/subnet_list"
}

locals {
  docker_compose = <<EOF
services:
  mmgis:
    image: ghcr.io/nasa-ammos/mmgis:development
    depends_on:
      - mmgis.db
    environment:
      SERVER                    : ${var.server}
      AUTH                      : none
      NODE_ENV                  : production
      DB_HOST                   : ${var.db_host}
      DATABASE_HOST             : ${var.db_host}
      DATABASE_PORT             : 5432
      DB_PORT                   : 5432
      DB_NAME                   : ${var.db_name}
      DB_USER                   : ${var.db_user}
      PORT                      : ${var.app_listening_port}
      DB_POOL_MAX               : ${var.db_pool_max}
      DB_POOL_TIMEOUT           : ${var.db_pool_timeout}
      DB_POOL_IDLE              : ${var.db_pool_idle}
      CSSO_GROUPS               : null
      VERBOSE_LOGGING           : ${var.verbose_logging}
      #FRAME_ANCESTORS           : ${var.frame_ancestors}
      #FRAME_SRC                 : ${var.frame_src}
      THIRD_PARTY_COOKIES       : ${var.third_party_cookies}
      ROOT_PATH                 : ${var.root_path}
      WEBSOCKET_ROOT_PATH       : ${var.websocket_root_path}
      CLEARANCE_NUMBER          : ${var.clearance_number}
      DISABLE_LINK_SHORTENER    : ${var.disable_link_shortener}
      HIDE_CONFIG               : ${var.hide_config}
      FORCE_CONFIG_PATH         : ${var.force_config_path}
      LEADS                     : null
      ENABLE_MMGIS_WEBSOCKETS   : ${var.enable_mmgis_websockets}
      ENABLE_CONFIG_WEBSOCKETS  : ${var.enable_config_websockets}
      ENABLE_CONFIG_OVERRIDE    : ${var.enable_config_override}
      MAIN_MISSION              : ${var.main_mission}
      SKIP_CLIENT_INITIAL_LOGIN : ${var.skip_client_initial_login}
      GENERATE_SOURCEMAP        : ${var.generate_sourcemap}
      SPICE_SCHEDULED_KERNEL_DOWNLOAD : ${var.spice_scheduled_kernel_download}
      SPICE_SCHEDULED_KERNEL_DOWNLOAD_ON_START : ${var.spice_scheduled_kernel_download_on_start}
      SPICE_SCHEDULED_KERNEL_cron_expr : ${var.spice_scheduled_kernel_cron_expr}
      SECRET                    : ${var.secret}
      DB_PASS                   : ${var.db_pass}
    ports:
      - 8888:8888
    networks:
      - app-network
    restart: always
    volumes:
      - /var/www/html/Missions/:/usr/src/app/Missions
  mmgis.db:
    image: postgis/postgis:16-3.4-alpine
    environment:
      POSTGRES_USER     : ${var.db_user}    
      POSTGRES_PASSWORD : ${var.db_pass}
    volumes:
      - mmgis-db:/var/lib/postgresql/data
    ports:
      - "${var.db_port}:5432"
    networks:
      - app-network
volumes:
  mmgis-db:

networks:
  app-network:
    driver: bridge
EOF
}


# Allow port 80 so we can connect to the container.
resource "aws_security_group" "allow_http" {
    name = "${var.venue}-${var.project}-allow_http-sg"
    description = "Show off how we run a docker-compose file."
    vpc_id = data.aws_ssm_parameter.vpc_id.value


    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Make sure to download the other files into the `modules/ec2-docker`
# directory
module "run-mmgis-ec2-docker" {
    source =  "./modules/ec2-docker"
    name = "mmgis-ec2-docker"
    key_name = var.key_name
    instance_type = "t3.medium"
    docker_compose_str = local.docker_compose
    subnet_id = var.subnet_id
    availability_zone = var.availability_zone
    project = var.project
    venue = var.venue
    vpc_security_group_ids = [aws_security_group.allow_http.id]
    associate_public_ip_address = true
    persistent_volume_size_gb = 20 
}