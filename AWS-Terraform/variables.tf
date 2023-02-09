# image id 변수
variable "image_id" {
  description = "The id of the machine image (AMI) to use for the server."
  type        = string
  default     = "" # "ami-0c76973fbe0ee100c" # Amazon Linux 2 (Seoul)
}

# instance type 변수
variable "instance_type" {
  description = "The Instance Type of the web server."
  type        = string
  default     = "t2.micro"
}

# server port 변수
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default = 80
}

# security group name 변수
variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "allow_http"
}