variable "aws_region" {
  description = "La región de AWS donde se crearán los recursos."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado para prefijos en nombres de recursos."
  type        = string
  default     = "iportfolio"
}

variable "environment" {
  description = "Entorno (ej. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags comunes para aplicar a todos los recursos que lo soporten."
  type        = map(string)
  default = {
    Project     = "iPortfolio"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

variable "ses_source_email" {
  description = "Email verificado en SES para enviar correos."
  type        = string
  default     = "xvclemente@gmail.com"
}

variable "contact_recipient_email" {
  description = "Email donde recibir los mensajes del formulario."
  type        = string
  default     = "xvclemente@gmail.com"
}

variable "ses_region" {
  description = "La región donde está configurado SES (puede ser diferente a aws_region)."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "web portafolio de Xavier Clemente"
  type        = string
  default     = "xvclemente.com"
}
