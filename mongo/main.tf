resource "aws_docdb_cluster_instance" "gamma_mongo_cluster_instances" {
  count              = 1
  identifier         = "gamma-${terraform.workspace}-mongo-cluster-instance-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.gamma_mongo_cluster.id
  instance_class     = "db.t3.medium"
  apply_immediately  = true

}

resource "aws_docdb_cluster" "gamma_mongo_cluster" {
  cluster_identifier              = "gamma-${terraform.workspace}-docdb-cluster"
  master_username                 = "foo"
  db_subnet_group_name            = var.mongo_subnet_group_name
  port = 27017
  master_password                 = var.mongo_password
  apply_immediately               = true
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.gamma_mongo_parameter_group.name
  skip_final_snapshot             = true
  vpc_security_group_ids          = [var.mongo_security_group]
}


resource "aws_docdb_cluster_parameter_group" "gamma_mongo_parameter_group" {
  family      = "docdb4.0"
  name        = "gamma-${terraform.workspace}-mongo-parameter-group"
  description = "docdb cluster parameter group"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}