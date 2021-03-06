resource "aws_security_group" "cluster_member" {
  name        = "${var.cluster_name}-cluster-member"
  vpc_id      = local.vpc_id

  ingress {
    description = "Control Plane API Endpoint"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Flannel VXLAN"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Kubelet"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Ingress Controller livenessProbe/readinessProbe"
    from_port   = 10254
    to_port     = 10254
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "NodePort for Distributing NodeToken"
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    self        = true
  }
}
