resource "aws_iam_role_policy" "gamma_ecs_policy" {
  name = "gamma-${terraform.workspace}-ecs-policy"
  role = aws_iam_role.gamma_ecs_execution_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [

          "autoscaling:Describe*",
          "cloudwatch:*",
          "logs:*",
          "sns:*",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "oam:ListSinks",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:RegisterTargets",
          "ecs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:CreateServiceLinkedRole"]
        Resource = "arn:aws:iam::*:role/aws-service-role/events.amazonaws.com/AWSServiceRoleForCloudWatchEvents*"

      }
    ]
  })

}

resource "aws_iam_role" "gamma_ecs_execution_role" {
  name = "gamma-${terraform.workspace}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_user" "gamma_upload_bucket_user" {
  name = "gamma-${terraform.workspace}upload-bucket-user"


}

resource "aws_iam_access_key" "gamma_upload_bucket_user" {
  user = aws_iam_user.gamma_upload_bucket_user.name
}

resource "aws_iam_user_policy" "lb_ro" {
  name = "test"
  user = aws_iam_user.gamma_upload_bucket_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": ["${var.gamma_upload_bucket_arn}",
      "${var.gamma_upload_bucket_arn}/*"]
    }
  ]
}
EOF
}


data "aws_iam_policy_document" "gamma_upload_bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.gamma_upload_bucket_user.arn]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      var.gamma_upload_bucket_arn,
      "${var.gamma_upload_bucket_arn}/*",
    ]
  }
}