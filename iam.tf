# Política personalizada para Route 53 y ACM
resource "aws_iam_policy" "route53_acm_policy" {
  name        = "${var.project_name}-Route53AndACMPolicy"
  description = "Policy for Route 53 and ACM permissions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "iam:CreatePolicy",
            "iam:AttachUserPolicy",
            "iam:GetPolicy",
            "iam:ListPolicies",
            "iam:DeletePolicy",
            "iam:DetachUserPolicy"
        ]
        Resource: "*"
      },        
      {
        Effect = "Allow"
        Action = [
          "route53:CreateHostedZone",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:GetChange",
          "route53:ChangeTagsForResource",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:AddTagsToCertificate",
          "acm:DeleteCertificate",
          "acm:ListTagsForCertificate"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Asociar la política personalizada Route53AndACMPolicy al usuario Xavi
resource "aws_iam_user_policy_attachment" "route53_acm_attach" {
  user       = "Xavi"
  policy_arn = aws_iam_policy.route53_acm_policy.arn
}

# Asociar políticas gestionadas por AWS existentes al usuario Xavi
resource "aws_iam_user_policy_attachment" "apigateway_admin_attach" {
  user       = "Xavi"
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
}

resource "aws_iam_user_policy_attachment" "s3_full_access_attach" {
  user       = "Xavi"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_user_policy_attachment" "ses_full_access_attach" {
  user       = "Xavi"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_user_policy_attachment" "lambda_full_access_attach" {
  user       = "Xavi"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_iam_user_policy_attachment" "cloudfront_full_access_attach" {
  user       = "Xavi"
  policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
}

resource "aws_iam_user_policy_attachment" "iam_full_access_attach" {
  user       = "Xavi"
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}