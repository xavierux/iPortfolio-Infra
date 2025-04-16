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