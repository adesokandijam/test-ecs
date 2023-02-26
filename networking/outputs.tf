output "gamma_vpc" {
  value = aws_vpc.gamma_vpc.id
}

output "public_subnet" {
  value = aws_subnet.gamma_public_subnet.*.id
}

output "rds_subnet_group_name" {
  value = aws_db_subnet_group.gamma_rds_sn_group.name
}

output "redis_subnet_group_name" {
  value = aws_elasticache_subnet_group.gamma_redis_sn_group.name
}

output "mongo_subnet_group_name" {
  value = aws_docdb_subnet_group.gamma_mongo_sn_group.name
}

output "loadbalancer_https_security_group" {
  value = aws_security_group.lb_sg.id
}

output "loadbalancer_http_security_group" {
  value = aws_security_group.lb_http_sg.id
}

output "apigw_security_group" {
  value = aws_security_group.apigw_sg.id
}

output "users_api_security_group" {
  value = aws_security_group.users_api_sg.id
}

output "rds_security_group" {
  value = aws_security_group.rds_sg.id
}

output "redis_security_group" {
  value = aws_security_group.redis_sg.id
}

output "game_engine_security_group" {
  value = aws_security_group.gameengine_sg.id
}

output "mongodb_security_group" {
  value = aws_security_group.mongo_sg.id
}

output "mongo_jumper_security_group" {
  value = aws_security_group.mongo_jumper_sg.id
}