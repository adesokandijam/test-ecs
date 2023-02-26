output "gamma_ecs_role_arn" {
  value = aws_iam_role.gamma_ecs_execution_role.arn
}

output "gamma_upload_bucket_policy" {
  value = data.aws_iam_policy_document.gamma_upload_bucket_policy.json
}

output "gamma_upload_user_access_keys" {
  value = [aws_iam_access_key.gamma_upload_bucket_user.id, aws_iam_access_key.gamma_upload_bucket_user.secret]
}