provider "aws" {
  region    = "ap-northeast-1"
  profile   = "shubham"
}

data "aws_vpc" "vpc" {
    }

resource "aws_security_group" "ec2_security_group" {
  
  vpc_id      = data.aws_vpc.vpc.id

  # allow access on port 8080
  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # allow access on port 22
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags   = {
    Name = "jenkins server security group"
  }
}

resource "aws_instance" "ec2_instance" {
  ami                    = "ami-078296f82eb463377"
  instance_type          = "t2.medium" 
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "shubham"

  tags = {
    Name = "Jenkins-Server"
  }
}

resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/shubham.pem")
    host        = aws_instance.ec2_instance.public_ip
  }

  # copy the install_jenkins.sh file from your computer to the ec2 instance 
  provisioner "file" {
    source      = "install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
  }

  # set permissions and run the install_jenkins.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_jenkins.sh",
      "sh /tmp/install_jenkins.sh",
      "sudo systemctl start docker"
    ]
  }


  depends_on = [aws_instance.ec2_instance]
}