output "access_key" {
  value     = module.iam.gamma_upload_user_access_keys
  sensitive = true
}