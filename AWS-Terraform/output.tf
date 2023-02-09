# public ip 출력 설정
output "public_ip" {
  # value       = aws_instance.web_pub.public_ip
  value       = "${aws_instance.web_pub.public_ip}:${var.server_port}"
  description = "The public IP address of the web server"
}
# private ip 출력 설정
output "private_ip" {
  # value       = aws_instance.web_pri.private_ip
  value       = aws_instance.web_pri.private_ip
  description = "The private IP address of the web server"
}
# db endpoint address 출력 설정
output "db_endpoint" {
  value       = aws_db_instance.large-db.endpoint
  description = "The Endpoint address of the db server"
}
# 로드밸런서 DNS output 출력 설정
output "alb_dns_name" {
  description = "The domain name of the load balancer"
  value = aws_lb.alb.dns_name
}