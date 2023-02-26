module "networking" {
  source           = "./networking"
  max_subnets      = 10
  public_sn_count  = 3
  private_sn_count = 2
  cidr_block       = "10.16.0.0/16"
  public_cidrs     = [for i in range(1, 255, 2) : cidrsubnet("10.16.0.0/16", 8, i)]
  private_cidrs    = [for i in range(0, 255, 2) : cidrsubnet("10.16.0.0/16", 8, i)]
}

module "loadbalancing" {
  source                  = "./loadbalancing"
  public_subnets          = module.networking.public_subnet
  gamma_vpc_id           = module.networking.gamma_vpc
  elb_healthy_threshold   = 2
  elb_unhealthy_threshold = 2
  elb_interval            = 30
  route53_zone_id = var.route53_zone_id
  elb_timeout             = 3
  gamma_lb_sg            = [module.networking.loadbalancer_https_security_group, module.networking.loadbalancer_http_security_group]
}

module "ecs" {
  source                = "./ecs"
  api_tg_arn            = module.loadbalancing.gamma_api_tg_arn
  gamma_lb             = module.loadbalancing.gamma_lb
  gamma_execution_role = module.iam.gamma_ecs_role_arn
  public_subnets        = module.networking.public_subnet
  users_tg_arn          = module.loadbalancing.gamma_user_tg_arn
  game_engine_tg_arn    = module.loadbalancing.gamma_game_engine_tg_arn
  apigw_sg              = module.networking.apigw_security_group
  users_api_sg          = module.networking.users_api_security_group
  game_engine_sg        = module.networking.game_engine_security_group
}

module "iam" {
  source                   = "./iam"
  gamma_upload_bucket_arn = module.s3.gamma_upload_bucket_arn
}

module "rds" {
  source               = "./rds"
  db_subnet_group_name = module.networking.rds_subnet_group_name
  rds_sg               = module.networking.rds_security_group
  db_password = var.db_password
}


module "redis" {
  source                  = "./redis"
  redis_subnet_group_name = module.networking.redis_subnet_group_name
  redis_sg                = module.networking.redis_security_group
}

module "mongo" {
  source                  = "./mongo"
  mongo_subnet_group_name = module.networking.mongo_subnet_group_name
  mongo_security_group    = module.networking.mongodb_security_group
  mongo_password = var.mongo_password
}

module "route53" {
  source        = "./route53"
  gamma_lb_dns = module.loadbalancing.gamma_lb_dns
  route53_zone_id = var.route53_zone_id
}

module "s3" {
  source               = "./s3"
  upload_bucket_policy = module.iam.gamma_upload_bucket_policy

}

module "ec2" {
  source                 = "./ec2"
  gamma_mongo_jumper_sg = module.networking.mongo_jumper_security_group
  public_subnet          = module.networking.public_subnet
}

