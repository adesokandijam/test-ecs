resource "aws_elasticache_cluster" "gamma_redis_cluster" {
  cluster_id           = "gamma-${terraform.workspace}-redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.x"
  port                 = 6379
  subnet_group_name    = var.redis_subnet_group_name
  security_group_ids   = [var.redis_sg]
}