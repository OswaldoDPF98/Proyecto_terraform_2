terraform-proyecto/
├── backend/
│   ├── main.tf                # Código para crear el bucket S3 + DynamoDB
│   └── variables.tf           # (opcional) Variables para el nombre del bucket, tabla, región
├── infraestructura/
│   ├── main.tf                # Recursos principales (EC2, VPC, etc.)
│   ├── variables.tf
│   ├── backend.tf             # Configuración del backend remoto
│   └── outputs.tf
└── README.md
