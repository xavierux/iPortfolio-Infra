output "s3_bucket_name" {
  description = "El nombre del bucket S3 creado para los archivos estáticos."
  value       = aws_s3_bucket.static_site.bucket
}

output "s3_bucket_arn" {
  description = "El ARN del bucket S3."
  value       = aws_s3_bucket.static_site.arn
}

# --- Salida para el nombre de dominio de CloudFront ---
output "cloudfront_domain_name" {
  description = "El nombre de dominio asignado a la distribución de CloudFront."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_distribution_id" {
  description = "El ID de la distribución de CloudFront."
  value       = aws_cloudfront_distribution.s3_distribution.id
}