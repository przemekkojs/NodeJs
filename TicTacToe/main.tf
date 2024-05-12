# AWS PROVIDER
provider "aws" {
  region = "us-east-1"
}

# SET UP VPC
resource "aws_vpc" "my_vpc" {
	cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
	
	tags = {
		Name = "my_vpc"
	}
}

# CREATE SUBNETS
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.101.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.102.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_subnet"
  }
}

# CREATE INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    name = "my_igw"
  }
}

# CREATE ROUTE TABLES
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# ASSOCIATE ROUTE TABLE WITH PUBLIC SUBNET
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# CONFIGURE SECURITY GROUPS
resource "aws_security_group" "backend_sg" {
  name        = "backend_security"
  description = "allow ssh, http traffic"
  vpc_id      =  aws_vpc.my_vpc.id


  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
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
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "sg"
  }
} 

resource "aws_security_group" "frontend_sg" {
  name        = "frontend_security"
  description = "allow ssh, http traffic"
  vpc_id      =  aws_vpc.my_vpc.id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Allow from any source
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "sg"
  }
} 

# DEPLOY EC2 INSTANCES
resource "aws_instance" "backend" {
  ami                         = "ami-080e1f13689e07408"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.backend_sg.id, aws_security_group.frontend_sg.id]
  user_data_replace_on_change = true
  user_data = <<EOF
                #!bin/bash
                # sudo mkdir -p /usr/local/lib/docker/cli-plugins
                # sudo curl -sL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose

                # sudo chown root:root /usr/local/lib/docker/cli-plugins/docker-compose
                # sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

                curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 
                apt-get install -y nodejs
                apt-get install -y apache2

                EOF
  tags = {
    Name = "Backend"
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "mkdir /home/ubuntu/app",
  #     "mkdir /tmp/app",
  #     "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - ",
  #     "sudo apt-get install -y nodejs"
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = "ubuntu"
  #     private_key = file("labsuser.pem")
  #     host        = self.public_ip
  #   }
  # }

  # provisioner "file" {
  #   source = "backend/src"
  #   destination = "/tmp/app"

  #   connection {
  #     type        = "ssh"
  #     user        = "ubuntu"
  #     private_key = file("labsuser.pem")
  #     host        = self.public_ip
  #   }
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo mv /tmp/app/ /home/ubuntu/",
  #     "cd /home/ubuntu/app/src/",
  #     "sudo mv backend.service /etc/systemd/system/backend.service",
  #     "sudo npm install",
  #     "sudo npm rebuild",
  #     "sudo systemctl enable backend",
  #     "sudo systemctl start backend"
  #   ]

  #   connection {
  #     type        = "ssh"
  #     user        = "ubuntu"
  #     private_key = file("labsuser.pem")
  #     host        = aws_instance.backend.public_ip
  #   }
  # }
}

# resource "aws_instance" "frontend" {
#   ami                         = "ami-080e1f13689e07408"
#   instance_type               = "t2.micro"
#   key_name                    = "vockey"
#   subnet_id                   = aws_subnet.public_subnet.id
#   associate_public_ip_address = "true"
#   vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
#   user_data_replace_on_change = true
#   tags = {
#     Name = "Frontend"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       #"mkdir /tmp/app",
#       "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - ",
#       "sudo apt-get install -y nodejs",
#       "sudo apt-get install -y apache2"
#     ]

#     connection {
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = file("labsuser.pem")
#       host        = self.public_ip
#     }
#   }

#   provisioner "file" {
#     source = "frontend/src/"
#     destination = "/tmp"

#     connection {
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = file("labsuser.pem")
#       host        = self.public_ip
#     }
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo mv /tmp/* /var/www/html/",
#       "cd /var/www/html/js",
#       "echo 'const socket = io(\"ws://${aws_instance.backend.public_ip}:8080/\");' | cat - client.js > temp && mv temp client.js",
#       "cd ..",
#       "sudo npm install",
#       "sudo npm rebuild",
#       "sudo systemctl enable apache2",
#       "sudo systemctl start apache2"
#     ]

#     connection {
#       type        = "ssh"
#       user        = "ubuntu"
#       private_key = file("labsuser.pem")
#       host        = self.public_ip
#     }
#   }
# }

# OUTPUT IP ADDRESSES
output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

# output "frontend_public_ip" {
#   value = aws_instance.frontend.public_ip
# }