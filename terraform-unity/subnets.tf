resource "aws_subnet" "subnet-uno" {
  cidr_block = "${cidrsubnet(aws_vpc.unity-infra-env.cidr_block, 3, 1)}"
  vpc_id = "${aws_vpc.unity-infra-env.id}"
  availability_zone = "us-east-1a"
}

resource "aws_route_table" "route-table-infra-env" {
  vpc_id = "${aws_vpc.unity-infra-env.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.infra-env-gw.id}"
  }
  tags = {
    Name = "infra-env-route-table"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.subnet-uno.id}"
  route_table_id = "${aws_route_table.route-table-infra-env.id}"
}
