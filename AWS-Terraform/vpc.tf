# vpc 생성하기
resource "aws_vpc" "main" {
    cidr_block = 10.0.0.0/16
    # instance_tenancy = "default"
    # enable_dns_support = true   두 개의 값은 기본값이 true 라 사용하지 않아도 됨
    enable_dns_hostnames = true
    
    tags = {
        Name = "large-vpc"
    }
}
# aws_internet_gateway 설정
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "large-igw"
  }
}
# public aws_subnet 설정
resource "aws_subnet" "pub_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone_id    = "apne2-az1"
  map_public_ip_on_launch = true

  tags = {
    Name = "large-subnet-public1-ap-northeast-2a"
  }
}

resource "aws_subnet" "pub_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone_id    = "apne2-az3"
  map_public_ip_on_launch = true

  tags = {
    Name = "large-subnet-public2-ap-northeast-2c"
  }
}
# public aws_route_table 설정
resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "large-rtb-public"
  }
}
# public aws_route_table_assoication 설정
resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_c" {
  subnet_id      = aws_subnet.pub_c.id
  route_table_id = aws_route_table.pub.id
}
# private aws_subnet 설정
resource "aws_subnet" "pri_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone_id    = "apne2-az1"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-subnet-private1-ap-northeast-2a"
  }
}

resource "aws_subnet" "pri_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone_id    = "apne2-az3"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-subnet-private2-ap-northeast-2c"
  }
}
# private aws_route_table 설정
resource "aws_route_table" "pri_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw_a.id
  }

  tags = {
    Name = "large-rtb-pribate1-ap-northeast-2a"
  }
}

resource "aws_route_table" "pri_c" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw_a.id
  }

  tags = {
    Name = "large-rtb-pribate2-ap-northeast-2c"
  }
}
# public aws_route_assoication 설정
resource "aws_route_table_association" "pri_a" {
  subnet_id      = aws_subnet.pri_a.id
  route_table_id = aws_route_table.pri_a.id
}

resource "aws_route_table_association" "pri_c" {
  subnet_id      = aws_subnet.pri_c.id
  route_table_id = aws_route_table.pri_c.id
}
# aws_eip 생성
resource "aws_eip" "pub_a" {
  vpc = true

  tags = {
    Name = "large-eip-ap-northeast-2a"
  }
}
# aws_nat_gateway 생성
resource "aws_nat_gateway" "gw_a" {
  allocation_id = aws_eip.pub_a.id
  subnet_id     = aws_subnet.pub_a.id

  tags = {
    Name = "tf-eip-ap-northeast-2a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

# depends_on은 NAT 게이트웨이가 internet 게이트웨이에 의존한다는 의미로
# internet 게이트웨이가 생성 후 nat 게이트웨이르르 생성하겠다는 의미입니다.