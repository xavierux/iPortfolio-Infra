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

# Rol IAM para la función Lambda
resource "aws_iam_role" "contact_lambda_role" {
  name = "${var.project_name}-contact-lambda-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
  tags = var.tags
}

# Política para Logs y SES
resource "aws_iam_policy" "contact_lambda_policy" {
  name        = "${var.project_name}-contact-lambda-policy-${var.environment}"
  description = "Permisos para logs y SES para Lambda de contacto"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail" # A veces necesario
        ]
        Effect   = "Allow"
        # ¡IMPORTANTE! Restringe el recurso al ARN de tu identidad verificada si es posible
        # o usa "*" si tienes problemas, pero es menos seguro.
        # El ARN de una identidad de email es: arn:aws:ses:REGION:ACCOUNT_ID:identity/your_email@example.com
        Resource = "arn:aws:ses:${var.ses_region}:${data.aws_caller_identity.current.account_id}:identity/${var.ses_source_email}"
        # Resource = "*" # Menos seguro, usar si lo anterior da problemas inicialmente
      }
    ]
  })
}

# Adjuntar política al rol
resource "aws_iam_role_policy_attachment" "contact_lambda_attach" {
  role       = aws_iam_role.contact_lambda_role.name
  policy_arn = aws_iam_policy.contact_lambda_policy.arn
}

# --- Código Lambda (Ejemplo: guardar en lambda_code/contact_form/lambda_function.py) ---
# Necesitarás crear un archivo ZIP con este código y sus dependencias (si las hubiera, boto3 está incluido)
data "archive_file" "contact_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code/contact_form" # Ruta a tu código Python
  output_path = "${path.module}/lambda_code/contact_form.zip"
}

# Función Lambda
resource "aws_lambda_function" "contact_form_handler" {
  function_name = "${var.project_name}-contact-handler-${var.environment}"
  filename      = data.archive_file.contact_lambda_zip.output_path
  source_code_hash = data.archive_file.contact_lambda_zip.output_base64sha256
  role          = aws_iam_role.contact_lambda_role.arn
  handler       = "lambda_function.lambda_handler" # Nombre_archivo.nombre_funcion
  runtime       = "python3.9" # O la versión de Python que prefieras
  timeout       = 10 # Segundos

  environment {
    variables = {
      RECIPIENT_EMAIL = var.contact_recipient_email
      SOURCE_EMAIL    = var.ses_source_email
      SES_REGION      = var.ses_region
    }
  }
  tags = var.tags
}

# API Gateway (HTTP API - más simple y barato)
resource "aws_apigatewayv2_api" "contact_api" {
  name          = "${var.project_name}-contact-api-${var.environment}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"] # Sé más específico en producción (ej. tu URL de CloudFront)
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }
  tags = var.tags
}

# Integración entre API Gateway y Lambda
resource "aws_apigatewayv2_integration" "contact_lambda_integration" {
  api_id           = aws_apigatewayv2_api.contact_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.contact_form_handler.invoke_arn
  payload_format_version = "2.0" # Recomendado para HTTP APIs
}

# Ruta para el formulario (/contact)
resource "aws_apigatewayv2_route" "contact_post_route" {
  api_id    = aws_apigatewayv2_api.contact_api.id
  route_key = "POST /contact" # La ruta que llamará tu JS
  target    = "integrations/${aws_apigatewayv2_integration.contact_lambda_integration.id}"
}

# Despliegue de la API (necesario para que sea accesible)
resource "aws_apigatewayv2_stage" "contact_api_stage" {
  api_id = aws_apigatewayv2_api.contact_api.id
  name   = "$default" # O un nombre como 'v1', '$default' es el más simple
  auto_deploy = true

  # Opcional: Configurar logging de API Gateway a CloudWatch
  # default_route_settings {
  #   throttling_burst_limit = 5
  #   throttling_rate_limit  = 10
  # }
  # access_log_settings {
  #   destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn # Necesitarías crear este Log Group
  #   format          = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.resourcePath $context.protocol\" $context.status $context.responseLength $context.requestId"
  # }
}

# Permiso para que API Gateway invoque Lambda
resource "aws_lambda_permission" "api_gw_lambda_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_form_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.contact_api.execution_arn}/*/*/contact" # Permite a cualquier ruta bajo /contact invocar
}

# Para obtener el ID de cuenta actual para el ARN de SES
data "aws_caller_identity" "current" {}
