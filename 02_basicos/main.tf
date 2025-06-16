terraform {
backend "s3" {
    bucket         = "directorio-terraform-estado"
    key            = "02_basicos/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bloqueo-terraform"
    encrypt        = true
}

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

resource "aws_s3_bucket_versioning" "estado_terraform_versioning" {
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

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "instancia_uno" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = 
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3
              mkdir -p /var/www/html
              echo "Hola, mundo 1!" > /var/www/html/index.html
              cd /var/www/html
              nohup python3 -m http.server 8080 &
              EOF
}

resource "aws_instance" "instancia_dos" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = 
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3
              mkdir -p /var/www/html
              echo "Hola, mundo 2!" > /var/www/html/index.html
              cd /var/www/html
              nohup python3 -m http.server 8080 &
              EOF
}

resource "aws_s3_bucket" "bucket_proyecto" {
  bucket = "directorio-terraform-ejemplo"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "version_bucket_proyecto" {
  bucket = aws_s3_bucket.bucket_proyecto.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "version_bucket_proyecto_encriptacion" {
  bucket = aws_s3_bucket.bucket_proyecto.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_vpc" "vpc_projecto" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_projecto" {
  vpc_id            = aws_vpc.vpc_projecto.id  
}

