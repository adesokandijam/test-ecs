resource "aws_db_instance" "gamma_mysql_db" {
  allocated_storage      = 10
  identifier             = "gamma-${terraform.workspace}-user-accounts"
  engine                 = "mysql"
  engine_version         = "8.0.31"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  publicly_accessible    = true
  skip_final_snapshot    = true
  deletion_protection    = false
  apply_immediately      = true
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_sg]
}