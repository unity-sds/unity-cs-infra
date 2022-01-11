resource "aws_internet_gateway" "infra-env-gw" {
  vpc_id = "${aws_vpc.unity-infra-env.id}"
  tags = {
    Name = "infra-env-gw"
  }
}
