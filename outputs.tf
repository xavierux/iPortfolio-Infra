output "s3_bucket_name" {
  description = "El nombre del bucket S3 creado para los archivos estáticos."
  value       = aws_s3_bucket.static_site.bucket
}

output "s3_bucket_arn" {
  description = "El ARN del bucket S3."
  value       = aws_s3_bucket.static_site.arn
}