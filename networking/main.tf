data "aws_availability_zones" "available" {}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "public_az" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "gamma_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "gamma-${terraform.workspace}-vpc"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "gamma_vpc_igw" {
  vpc_id = aws_vpc.gamma_vpc.id
  tags = {
    "Name" = "gamma-${terraform.workspace}-igw"
  }
}

resource "aws_subnet" "gamma_public_subnet" {
  count                   = var.public_sn_count
  cidr_block              = var.public_cidrs[count.index]
  vpc_id                  = aws_vpc.gamma_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.public_az.result[count.index]
  tags = {
    "Name" = "gamma-${terraform.workspace}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "gamma_private_subnet" {
  count                   = var.private_sn_count
  cidr_block              = var.private_cidrs[count.index]
  vpc_id                  = aws_vpc.gamma_vpc.id
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.public_az.result[count.index]
  tags = {
    "Name" = "gamma-${terraform.workspace}-private-subnet-${count.index + 1}"
  }
}

resource "aws_db_subnet_group" "gamma_rds_sn_group" {
  name       = "gamma-${terraform.workspace}-rds-subnet-group"
  subnet_ids = terraform.workspace == "beta" ? aws_subnet.gamma_public_subnet.*.id : aws_subnet.gamma_private_subnet.*.id
  tags = {
    "Name" = "gamma-${terraform.workspace}-rds-subnet-group"
  }
}

resource "aws_elasticache_subnet_group" "gamma_redis_sn_group" {
  name       = "gamma-${terraform.workspace}-redis-subnet-group"
  subnet_ids = aws_subnet.gamma_private_subnet.*.id
  tags = {
    "Name" = "gamma-${terraform.workspace}-redis-subnet-group"
  }
}

resource "aws_docdb_subnet_group" "gamma_mongo_sn_group" {
  name       = "gamma-${terraform.workspace}-docdb-subnet-group"
  subnet_ids = aws_subnet.gamma_private_subnet.*.id
  tags = {
    "Name" = "gamma-${terraform.workspace}-docdb-subnet-group"
  }
}

resource "aws_route_table" "gamma_public_route" {
  vpc_id = aws_vpc.gamma_vpc.id
  tags = {
    "Name" = "gamma-${terraform.workspace}-public-route"
  }
}

resource "aws_route" "gamma_default_route" {
  route_table_id         = aws_route_table.gamma_public_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gamma_vpc_igw.id
}

resource "aws_default_route_table" "gamma_private_route" {
  default_route_table_id = aws_route_table.gamma_public_route.id
  tags = {
    "Name" = "gamma-${terraform.workspace}-private-route"
  }
}

resource "aws_route_table_association" "gamma_public_asso" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.gamma_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.gamma_public_route.id
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow HTTP access into Loadbalancer"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "loadbalancer security group"
  }
}

resource "aws_security_group" "lb_http_sg" {
  name        = "lb_http_sg"
  description = "Allow HTTPS access into Loadbalancer"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "loadbalancer http security group"
  }
}

resource "aws_security_group" "apigw_sg" {
  name        = "apigw_sg"
  description = "Allow HTTP access into APIGW service from the loadbalancers"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description     = "TLS from VPC"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id, aws_security_group.lb_http_sg.id]
    cidr_blocks     = [var.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "apigw security group"
  }
}
resource "aws_security_group" "users_api_sg" {
  name        = "users_api_sg"
  description = "Allow HTTP access into Users API from loadbalancer and other other services"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description     = "TLS from VPC"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id, aws_security_group.lb_http_sg.id, aws_security_group.apigw_sg.id, aws_security_group.gameengine_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "users_api security group"
  }
}
resource "aws_security_group" "gameengine_sg" {
  name        = "game_engine_sg"
  description = "Allow HTTP access from loadbalancer"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description     = "TLS from VPC"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "game engine security group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow TCP access into database from user security group"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description     = "TLS from VPC"
    from_port       = 3306
    to_port         = 3306
    cidr_blocks     = ["0.0.0.0/0"]
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id, aws_security_group.users_api_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mysql security group"
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "redis_sg"
  description = "Allow HTTP access into redis cluster for loadbalancer"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description     = "TLS from VPC"
    from_port       = 6379
    to_port         = 6379
    cidr_blocks     = [var.cidr_block]
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "redis security group"
  }
}


resource "aws_security_group" "mongo_sg" {
  name        = "mongo_sg"
  description = "Allow tcp access to mongo cluster from lb"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description     = "TLS from VPC"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    cidr_blocks     = [var.cidr_block]
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mongodb security group"
  }
}


resource "aws_security_group" "mongo_jumper_sg" {
  name        = "mongo__jumper_sg"
  description = "Allow ssh into the mongo db cluster"
  vpc_id      = aws_vpc.gamma_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mongodb jumper security group"
  }
}

