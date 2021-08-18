# Security group for public subnet resources
resource "aws_security_group" "public_sg" {
  name   = "public-sg"
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "public-sg-${var.environment}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Security group traffic rules
## Ingress rule
resource "aws_security_group_rule" "sg_ingress_public_22" {
  security_group_id = aws_security_group.public_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

## Egress rule
resource "aws_security_group_rule" "sg_egress_public" {
  security_group_id = aws_security_group.public_sg.id
  type              = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}