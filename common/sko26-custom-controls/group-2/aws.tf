resource "aws_security_group" "this" {
  name        = "sko-2025-security-group-${var.group_id}"
  description = "Allow SSH traffic"
  vpc_id      = module.vpc.vpc_id

  depends_on = [module.vpc]
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}


