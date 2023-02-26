output "gamma_lb" {
  value = aws_lb.gamma_lb.id
}

output "gamma_api_tg_arn" {
  value = aws_lb_target_group.gamma_api_tg.arn
}

output "gamma_user_tg_arn" {
  value = aws_lb_target_group.gamma_users_tg.arn
}

output "gamma_game_engine_tg_arn" {
  value = aws_lb_target_group.gamma_game_engine_tg.arn
}

output "gamma_lb_dns" {
  value = aws_lb.gamma_lb.dns_name
}