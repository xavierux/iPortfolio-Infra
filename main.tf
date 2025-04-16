# Bucket S3 para alojar los archivos estáticos del sitio web
resource "aws_s3_bucket" "static_site" {
  # Nombre único global para el bucket S3
  bucket = "${var.project_name}-static-site-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = var.tags
}

# Asegura que el nombre del bucket sea único añadiendo un sufijo aleatorio
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Bloquea el acceso público por defecto (recomendado, se ajustará si usas CloudFront)
resource "aws_s3_bucket_public_access_block" "static_site_public_access" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}