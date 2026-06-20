resource "aws_sqs_queue" "app_queue" {
  name                      = "k3s-app-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 20    

  tags = { Environment = "Production" }
}

output "sqs_url" {
  value       = aws_sqs_queue.app_queue.id
  description = "URL da fila SQS para injetar na sua aplicação"
}