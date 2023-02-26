data "aws_ami" "server_ami" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}


resource "aws_key_pair" "gamma_key_pair" {
  key_name = "gamma-${terraform.workspace}-key-pair"
  public_key = file("/Users/abdulmajidadesokan/.ssh/id_rsa.pub")
}


resource "aws_instance" "gamma_mongo_jumper" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.server_ami.id
  key_name = aws_key_pair.gamma_key_pair.key_name

  tags = {
    Name = "gamma-${terraform.workspace}-mongo-jumper"
  }
  vpc_security_group_ids = [var.gamma_mongo_jumper_sg]
  subnet_id              = var.public_subnet[0]
  root_block_device {
    volume_size = 8
  }

}

