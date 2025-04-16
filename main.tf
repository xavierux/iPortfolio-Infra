# Bucket S3 para alojar los archivos estáticos del sitio web
resource "aws_s3_bucket" "static_site" {
  # Nombre único global para el bucket S3
  bucket = "${var.project_name}-static-site-${var.environment}-${random_id.bucket_suffix.hex}"
  tags   = var.tags
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

# --- Origin Access Control (OAC) para S3 ---
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}-s3-oac-${var.environment}"
  description                       = "OAC for S3 bucket ${aws_s3_bucket.static_site.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- Política del Bucket S3 para permitir acceso a CloudFront via OAC ---
resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.static_site.id
  policy = data.aws_iam_policy_document.s3_policy_document.json
}

# --- Documento de Política IAM para S3 ---
data "aws_iam_policy_document" "s3_policy_document" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site.arn}/*"] # Permite leer objetos dentro del bucket

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    # Condición para asegurar que solo TU distribución CloudFront puede acceder
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}


# --- Distribución de CloudFront ---
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name # Importante usar el dominio regional
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = "S3-${var.project_name}-${var.environment}" # Un ID local para este origen
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name}"
  default_root_object = "index.html" # Archivo a servir si se pide la raíz "/"

  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]                  # Métodos permitidos
    cached_methods   = ["GET", "HEAD"]                             # Métodos cacheados
    target_origin_id = "S3-${var.project_name}-${var.environment}" # ID del origen definido arriba

    forwarded_values {
      query_string = false # No reenvía query strings a S3 (típico para sitios estáticos)
      cookies {
        forward = "none" # No reenvía cookies a S3
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Redirige HTTP a HTTPS
    min_ttl                = 0
    default_ttl            = 3600  # Tiempo en caché por defecto (1 hora)
    max_ttl                = 86400 # Tiempo máximo en caché (1 día)
  }

  # Restricciones (puedes añadir restricciones geográficas si lo necesitas)
  restrictions {
    geo_restriction {
      restriction_type = "none" # Sin restricciones geográficas por defecto
    }
  }

  # Cómo CloudFront maneja los errores de S3 (opcional pero recomendado)
  custom_error_response {
    error_caching_min_ttl = 300           # Cachea la respuesta de error por 5 min
    error_code            = 403           # Error "Forbidden" de S3
    response_code         = 404           # Transfórmalo en "Not Found" para el usuario
    response_page_path    = "/index.html" # Muestra index.html (o una página de error específica /404.html)
  }
  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404 # Error "Not Found" de S3
    response_code         = 404
    response_page_path    = "/index.html" # Muestra index.html (o /404.html)
  }

  tags = var.tags

}