// variables.tf
variable "name" {
  description = "Name for the EFS volume."
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC into which to create the EFS volume."
  type        = string
}

variable "tags" {
  description = "Additional tags to add to the EFS volume."
  default     = {}
}

variable "security_group_ids" {
  description = "The list of inbound security group IDs which will reach the EFS volume."
  default     = []
}

// data.tf
data "aws_vpc" "main" {
  tags = {
    name = var.vpc_name
  }
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

// main.tf
resource "aws_efs_file_system" "volume" {
  tags = merge(
    { Name = var.name },
    var.tags
  )
}

resource "aws_security_group" "volume" {
  name        = "${var.name}-volume-sg"
  vpc_id      = data.aws_vpc.main.id

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.security_group_ids
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = var.security_group_ids
  }
}


resource "aws_efs_mount_target" "per_subnet" {
  for_each        = toset(data.aws_subnet_ids.main.ids)
  file_system_id  = aws_efs_file_system.volume.id
  subnet_id       = each.value
  security_groups = [aws_security_group.volume.id]
}

// outputs.tf
output "dns_name" {
  value = aws_efs_file_system.volume.dns_name
}
