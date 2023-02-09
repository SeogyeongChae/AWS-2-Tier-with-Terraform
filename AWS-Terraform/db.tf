# DB security group 설정
resource "aws_security_group" "db" {
  name_prefix = var.db_security_group_name
  description = "Allow MYSQL inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "MYSQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.db_security_group_name # "allow_mysql_db"
  }
}
# DB subnet group 설정
resource "aws_db_subnet_group" "large-db" {
  name       = "large-db"
  subnet_ids = [aws_subnet.pri_a.id, aws_subnet.pri_c.id]

  tags = {
    Name = "Terraform DB subnet group"
  }
}
# DB 설정
resource "aws_db_instance" "large-db" {
  identifier_prefix   = "large-db"
  allocated_storage   = 10
  engine              = "mysql"
  engine_version      = "5.7"
  instance_class      = "db.t3.micro"
  db_name             = "large"
  username            = "db"
  password            = "password"
  skip_final_snapshot = true
  # multi_az               = "false"
  db_subnet_group_name   = aws_db_subnet_group.large-db.name
  vpc_security_group_ids = [aws_security_group.db.id]
}