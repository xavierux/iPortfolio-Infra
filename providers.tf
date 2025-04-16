terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Puedes ajustar la versión, pero esta es reciente (Abril 2025)
    }
  }

  required_version = ">= 1.0" # Especifica la versión mínima de Terraform
}

# Configura el proveedor de AWS
# Terraform buscará las credenciales automáticamente (variables de entorno, ~/.aws/credentials, etc.)
provider "aws" {
  region = var.aws_region
}