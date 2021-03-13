resource "aws_iam_role" "cluster_member" {
  name = "${var.cluster_name}-cluster-member"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Cluster = var.cluster_name
  }
}

resource "aws_iam_policy" "cluster_member" {
  name   = "${var.cluster_name}-cluster-member"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_member" {
  role       = aws_iam_role.cluster_member.name
  policy_arn = aws_iam_policy.cluster_member.arn
}


resource "aws_iam_instance_profile" "cluster_member" {
  name = "${var.cluster_name}-cluster-member"
  role = aws_iam_role.cluster_member.name
}
