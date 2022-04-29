resource "aws_ecr_repository" "repository" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "policy" {
  repository = aws_ecr_repository.repository.name
  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" : [
      {
        "Sid"       = format("%s-node", var.name),
        "Effect"    = "Allow",
        "Principal" = "*",
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
      },
      {
        "Sid"       = format("%s-remote", var.name),
        "Effect"    = "Allow",
        "Principal" = "*",
        "Action" : [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
        "Condition" = {
          "IpAddress" : {
            "aws:SourceIp" : var.public_access_cidrs
          }
        }
      }
    ]
  })
}