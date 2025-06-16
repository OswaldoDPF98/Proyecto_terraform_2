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
  subnet_id     = aws_subnet.subnet_projecto.id
  vpc_security_group_ids = [aws_security_group.grupo_seguridad.id]
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
    subnet_id     = aws_subnet.subnet_projecto.id
  vpc_security_group_ids = [aws_security_group.grupo_seguridad.id]
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

resource "aws_security_group" "grupo_seguridad" {
  name        = "grupo_seguridad"
  description = "Grupo de seguridad para el proyecto"
  vpc_id      = aws_vpc.vpc_projecto.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.balanceador_carga.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: página no encontrada"
      status_code  = "404"
  }
}
}

resource "aws_lb_target_group" "instancias" {
  name     = "instancias"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_projecto.id

  health_check {
    path                = "/"
    protocol           = "HTTP"
    matcher            = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  } 
}

resource "aws_lb_target_group_attachment" "instancia_uno" {
  target_group_arn = aws_lb_target_group.instancias.arn
  target_id        = aws_instance.instancia_uno.id
  port             = 8080
  
}

resource "aws_lb_target_group_attachment" "instancia_dos" {
  target_group_arn = aws_lb_target_group.instancias.arn
  target_id        = aws_instance.instancia_dos.id
  port             = 8080
  
}

resource "aws_lb_listener_rule" "instancias" {
  listener_arn = aws_lb_listener.http_listener.arn
    priority     = 100

    condition {
      path_pattern {
        values = ["*"]
      }
    }

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.instancias.arn
    }
}

resource "aws_security_group" "grupo_seguridad_lb" {
  name        = "grupo_seguridad_lb"
  description = "Grupo de seguridad para el balanceador de carga"
}

resource "aws_security_group_rule" "permitir_http_ingreso" {
  type              = "ingress"
  security_group_id = aws_security_group.grupo_seguridad_lb.id

  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "permitir_http_egreso" {
  type              = "egress"
  security_group_id = aws_security_group.grupo_seguridad_lb.id

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "balanceador_carga" {
  name               = "balanceador-carga"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.grupo_seguridad_lb.id]
  subnets            = [aws_subnet.subnet_projecto.id]  
}

resource "aws_route53_zone" "zona_dns" {
  name = "dev.local."
}

resource "aws_route53_record" "registro_dns" {
  zone_id = aws_route53_zone.zona_dns.zone_id
  name    = "ejemplo.dev.local"
  type    = "A"

  alias {
    name                   = aws_lb.balanceador_carga.dns_name
    zone_id                = aws_lb.balanceador_carga.zone_id
    evaluate_target_health = true
  }
}

resource "aws_db_instance" "base_datos" {
  engine                  = "postgres"
  engine_version          = "14.7"
  instance_class          = "db.t2.micro"
  allocated_storage       = 20
  storage_type            = "standard"
  username                = "admin"
  password                = "password1234"
  db_name                 = "mi_base_datos"
  skip_final_snapshot     = true  
}