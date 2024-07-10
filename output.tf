output "instance_public_ip_url" {
  description = "Apache Servers Public IP URL"
  value       = ["http://${aws_instance.apache_server1.public_ip}", "http://${aws_instance.apache_server2.public_ip}"]
}

output "instance_public_dns" {
  description = "Apache Servers Public DNS"
  value       = ["http://${aws_instance.apache_server1.public_dns}", "http://${aws_instance.apache_server2.public_dns}"]
}

