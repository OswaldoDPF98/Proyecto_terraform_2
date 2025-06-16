terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "estado_terraform" {
  bucket = "directorio-terraform-estado"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "estado_terraform_encriptacion" {
  bucket = aws_s3_bucket.estado_terraform.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "estado_terraform_versionado" {
  bucket = aws_s3_bucket.estado_terraform.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "bloqueo_terraform" {
  name         = "bloqueo-terraform"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
