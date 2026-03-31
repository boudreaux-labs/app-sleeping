output "bucket_name" {
  value = aws_s3_bucket.sleeping.id
}

output "cf_distribution_id" {
  value = aws_cloudfront_distribution.sleeping.id
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.sleeping.domain_name
}
