provider "aws" {
  region = var.aws_region
}
resource "aws_security_group" "sg" {
  name        = "rayane-sg"
  description = "Security group for rayane"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
    Name = "rayane-sg"
  }

}
resource "aws_instance" "web_rayane" {
  ami           = var.vm_image
  instance_type = var.vm_instance_type

  subnet_id = aws_subnet.subnet.id

  key_name = aws_key_pair.key_rayane.key_name   

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.sg.id]
}
resource "aws_subnet" "subnet" {
  vpc_id     = var.vpc_id
  cidr_block = "172.31.160.0/24"
  tags = {
    Name = "rayane-subnet"
  }
}

resource "aws_key_pair" "key_rayane" {
  key_name   = "rayane-key"
  public_key = file("//wsl$/Ubuntu/home/rayaneslimani/.ssh/terraform-ipssi.pub")
}