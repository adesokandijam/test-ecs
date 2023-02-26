resource "aws_s3_bucket" "gamma_upload_bucket" {
  bucket = "gamma-${terraform.workspace}-upload-bucket"

  tags = {
    "Name"      = "gamma-${terraform.workspace}-upload-bucket"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket_acl" "gamma_private_acl" {
  bucket = aws_s3_bucket.gamma_upload_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "gamma_upload_bucket_public_access_block" {
  bucket = aws_s3_bucket.gamma_upload_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.gamma_upload_bucket.id
  policy = var.upload_bucket_policy
}



resource "aws_s3_access_point" "gamma_upload_bucket_access_point" {
  bucket = aws_s3_bucket.gamma_upload_bucket.id
  name   = "gamma-${terraform.workspace}-upload-bucket-access-point"
  public_access_block_configuration {
    block_public_acls       = true
    ignore_public_acls      = true
    block_public_policy     = true
    restrict_public_buckets = true
  }
}