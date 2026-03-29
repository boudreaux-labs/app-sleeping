locals {
  bucket_name  = "boudreaux-labs-sleeping-page"
  domain_names = ["sleeping.boudreauxlabs.com", "www.boudreauxlabs.com"]
}

# ------------------------------------------------------------
# S3 bucket
# ------------------------------------------------------------

resource "aws_s3_bucket" "sleeping" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "sleeping" {
  bucket                  = aws_s3_bucket.sleeping.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "sleeping" {
  bucket = aws_s3_bucket.sleeping.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ------------------------------------------------------------
# CloudFront Origin Access Control
# ------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "sleeping" {
  name                              = "sleeping-page-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ------------------------------------------------------------
# S3 bucket policy — allow CloudFront OAC only
# ------------------------------------------------------------

resource "aws_s3_bucket_policy" "sleeping" {
  bucket = aws_s3_bucket.sleeping.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.sleeping.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.sleeping.arn
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------
# CloudFront distribution
# ------------------------------------------------------------

resource "aws_cloudfront_distribution" "sleeping" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = local.domain_names
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.sleeping.bucket_regional_domain_name
    origin_id                = "s3-sleeping"
    origin_access_control_id = aws_cloudfront_origin_access_control.sleeping.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-sleeping"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 3600
  }

  # SPA fallback — serve index.html for 403/404 from S3
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# ------------------------------------------------------------
# Route53 record
# ------------------------------------------------------------

data "aws_route53_zone" "boudreauxlabs" {
  name = "boudreauxlabs.com"
}

resource "aws_route53_record" "sleeping" {
  zone_id = data.aws_route53_zone.boudreauxlabs.zone_id
  name    = "sleeping.boudreauxlabs.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.sleeping.domain_name
    zone_id                = aws_cloudfront_distribution.sleeping.hosted_zone_id
    evaluate_target_health = false
  }
}

# ------------------------------------------------------------
# IAM OIDC role for deploy pipeline
# ------------------------------------------------------------

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "deploy" {
  name = "app-sleeping-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:boudreaux-labs/app-sleeping:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "deploy" {
  name = "deploy-policy"
  role = aws_iam_role.deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Deploy"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.sleeping.arn,
          "${aws_s3_bucket.sleeping.arn}/*"
        ]
      },
      {
        Sid      = "CloudFrontInvalidate"
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = aws_cloudfront_distribution.sleeping.arn
      },
      {
        Sid    = "SSMRead"
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = [
          "arn:aws:ssm:us-east-1:842851109414:parameter/app-sleeping/*"
        ]
      }
    ]
  })
}

# ------------------------------------------------------------
# SSM parameters — consumed by deploy pipeline
# ------------------------------------------------------------

resource "aws_ssm_parameter" "bucket_name" {
  name  = "/app-sleeping/bucket_name"
  type  = "String"
  value = aws_s3_bucket.sleeping.id
}

resource "aws_ssm_parameter" "cf_distribution_id" {
  name  = "/app-sleeping/cf_distribution_id"
  type  = "String"
  value = aws_cloudfront_distribution.sleeping.id
}

resource "aws_ssm_parameter" "cf_domain" {
  name  = "/app-sleeping/cf_domain"
  type  = "String"
  value = aws_cloudfront_distribution.sleeping.domain_name
}

resource "aws_ssm_parameter" "cf_hosted_zone_id" {
  name  = "/app-sleeping/cf_hosted_zone_id"
  type  = "String"
  value = aws_cloudfront_distribution.sleeping.hosted_zone_id
}
