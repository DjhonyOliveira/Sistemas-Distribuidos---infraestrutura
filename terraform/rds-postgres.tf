resource "aws_db_subnet_group" "rds_subnets" {
  name       = "k3s-rds-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

resource "aws_db_instance" "postgres" {
  identifier             = "k3s-postgres-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  
  db_name                = "bilheteriapark"
  username               = "bilheteria"
  password               = "bilheteria123!"
  
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  skip_final_snapshot    = true
  publicly_accessible    = false
}

output "rds_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "Use este endpoint para conectar suas apps ao banco"
}

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials-secret"
    namespace = "default"
  }

  data = {
    host     = aws_db_instance.postgres.address
    username = aws_db_instance.postgres.username
    password = aws_db_instance.postgres.password
    dbname   = aws_db_instance.postgres.db_name
  }
}