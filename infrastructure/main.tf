terraform {
  required_version = ">=1.9.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.72.1"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_availability_zones" "availability_zones" {}

locals {
  azs = slice(data.aws_availability_zones.availability_zones.names, 0, 3)
  vpc_cidr = "10.0.0.0/16"
  cidr_block_public = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  cidr_block_private = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  vpc_name = "My VPC"
  public_subnet_name = "Public Subnet"
  private_subnet_name = "Private Subnet"
  gateway_name = "Internet Gateway"
  public_route_table_name = "Public Route Table"
  private_route_table_name = "Private Route Table"
  public_security_groups_name = "Public Security Group"
  private_security_groups_name = "Private Security Group"
  nat_gateway_name = "NAT Gateway"
  eks_name = "EKS_Cluster"
  fargate_profile_name = "Fargate_Profile"
}

resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${local.vpc_name}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.cidr_block_private[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${local.public_subnet_name}-${count.index}"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.cidr_block_public[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${local.public_subnet_name}-${count.index}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  
  tags = {
    Name = "${local.gateway_name}"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    "Name" = "${local.public_route_table_name}"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    "Name" = "${local.private_route_table_name}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on = [aws_internet_gateway.internet_gateway]

  allocation_id = aws_eip.elastic_ip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "${local.nat_gateway_name}"
  }
}

resource "aws_eip" "elastic_ip" {
  domain = "vpc"

  tags = {
    Name = "${local.nat_gateway_name}-Elastic-IP"
  }
}

resource "aws_route_table_association" "public_association" {
  for_each       = { for k, v in aws_subnet.public_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_association" {
  for_each       = { for k, v in aws_subnet.private_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "public_security_group" {
  name        = "${local.public_security_groups_name}"
  description = "${local.public_security_groups_name}"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.public_security_groups_name}"
  }

  ingress = [
    {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }]

  egress = [
    {
      description      = "Allow all outgoing traffics"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

resource "aws_security_group" "private_security_group" {
  name        = "${local.private_security_groups_name}"
  description = "${local.private_security_groups_name}"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Name" = "${local.private_security_groups_name}"
  }

  ingress = [
    {
      description      = "Allow all ip from vpc"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.vpc.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }]

  egress = [
    {
      description      = "Allow all outgoing traffics"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

resource "aws_eks_cluster" "eks" {
  name = "${local.eks_name}"
  upgrade_policy {
    support_type = "STANDARD"
  }
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
  vpc_config {
    subnet_ids = [for subnet in aws_subnet.public_subnet : subnet.id]
    endpoint_private_access = false
    endpoint_public_access = true
  }
  role_arn = aws_iam_role.eks_role.arn
  version = "1.30"
}

resource "aws_eks_addon" "cni" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "core_dns" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "pod_identity_webhook" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.3.2-eksbuild.2"
}

resource "aws_iam_role" "eks_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name = aws_eks_cluster.eks.name
  fargate_profile_name = local.fargate_profile_name
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]

  selector {
    namespace = "default"
  }

  selector {
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kube-dns"
    }
  }

  selector {
    namespace = "front-end"
  }

  selector {
    namespace = "argocd"
  }
}

resource "aws_eks_access_entry" "access_entry" {
  cluster_name = aws_eks_cluster.eks.name
  principal_arn = var.iam_user_arn
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_policy_association" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.iam_user_arn

  access_scope {
    type       = "cluster"
  }
}