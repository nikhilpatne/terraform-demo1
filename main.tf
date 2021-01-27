#  Create VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = var.vpc.cidr_block
  tags = {
    Name = var.vpc.Name
  }
}

# Declare the data source for Availability zones
data "aws_availability_zones" "azs" {
  state = "available"
}

#  Create Subnet
resource "aws_subnet" "subnet-1" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "production_subnet"
  }
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}


# 3. Create Custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  #  Route for IPv4
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  #  Route for Ipv6
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Production-route"
  }
}


# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = var.security_group
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}



# 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}


# # 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  instance                  = aws_instance.web-server-instance.id
  depends_on                = [aws_internet_gateway.gw]
}


# resource "aws_eip_association" "eip_assoc" {
#   instance_id   = aws_instance.web-server-instance.id
#   allocation_id = aws_eip.one.id
# }


# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "web-server-instance" {
  ami               = var.ami
  instance_type     = var.instance_type
  availability_zone = "us-east-2a"
  key_name          = var.key_name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = file("install_web_server.sh")
  tags      = var.instance_tag

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("/home/gslab/Downloads/nikhil-ec2.pem")
  }

  provisioner "file" {
    content     = "nikhil"
    destination = "/home/ubuntu/nikhil.txt"
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> /home/gslab/Desktop/public_ips.txt"
  }

  provisioner "remote-exec" {
    inline = [
      "echo Private Ip: ${self.private_ip} >> /home/ubuntu/private_ip.txt",
      "sudo chmod 777 /home/ubuntu/private_ip.txt"
    ]
  }

}



output "server_public_ip" {
  value = aws_eip.one.public_ip
}

output "server_private_ip" {
  value = aws_instance.web-server-instance.private_ip
}

output "instance_id" {
  value = aws_instance.web-server-instance.id
}


variable "aws_region" {}

variable "vpc" {
  type = object({
    Name       = string
    cidr_block = string
  })
  default = {
    Name       = "Development01"
    cidr_block = "10.0.0.0/16"
  }
}

variable "instance_tag" {
  type = object({
    Name = string
  })
  description = "Instance tag/Name to instance"
  default = {
    Name = "web-server"
  }
}

variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "t2.nano"
}

variable "key_name" {
  type        = string
  description = "Name of the pem/json private key (Required to connect instance)"
  default     = "nikhil-ec2"
}

variable "security_group" {
  type        = string
  description = "Name of the security group"
  default     = "allow_web"
}


variable "ami" {
  type        = string
  description = "The id of the machine image (AMI) to use for the server."
  default     = "ami-0a91cd140a1fc148a"

  #   validation {
  #     condition     = length(var.ami) > 4 && substr(var.ami, 0, 4) == "ami-"
  #     error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  #   }
}






