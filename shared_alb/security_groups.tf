resource "aws_security_group" "upstream" {
  name        = "${var.name}-upstream"
  vpc_id      = local.vpc_id

  tags = {
    ALB = var.name
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egress_cidr_blocks
  }
}

resource "aws_security_group" "downstream" {
  name        = "${var.name}-downstream"
  vpc_id      = local.vpc_id

  tags = {
    ALB = var.name
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.upstream.id]
  }

  # Range of ports for use with NodePorts to leverage ALB Healthchecks.
  # 30000 is reserved to use for distributing the node-token between cluster members.
  ingress {
    from_port       = 30001
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.upstream.id]
  }
}
