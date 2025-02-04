resource "aws_lb" "this" {
  name               = "sko-2025-load-balancer-${var.group_id}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false
  depends_on                 = [aws_security_group.this]
}

resource "aws_security_group" "this" {
  name        = "sko-2025-security-group-${var.group_id}"
  description = "Allow all traffic"
  vpc_id      = module.vpc.vpc_id

  depends_on = [module.vpc]
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
}
