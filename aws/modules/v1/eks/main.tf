locals {
  cluster_security_group_rules = {
    ingress_nodes_api = {
      description = "allow HTTPS from node groups to cluster API"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
    }
    egress_api_nodes = {
      description = "allow HTTPS from cluster API to node groups"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
    }
    egress_nodes_kubelet = {
      description = "allow management from cluster API to node kubelets"
      protocol    = "tcp"
      from_port   = 10250
      to_port     = 10250
      type        = "egress"
    }
  }
  cluster_security_group_rules_object = toset(flatten([
    for k1, v1 in var.clusters : [
      for k2, v2 in local.cluster_security_group_rules : {
        cluster               = k1
        create_security_group = v1.create_security_group
        description           = v2.description
        name                  = k2
        protocol              = v2.protocol
        from_port             = v2.from_port
        to_port               = v2.to_port
        type                  = v2.type
      }
    ] if v1.create_security_group == true
  ]))
  cluster_subnets_list = toset(flatten([
    for k1, v1 in var.clusters : [
      for v2 in v1.subnets : [v2]
    ]
  ]))
  cluster_subnets = toset(flatten([
    for k1, v1 in var.clusters : [
      for v2 in v1.subnets : {
        cluster = k1
        subnet  = v2
      }
    ]
  ]))
  cluster_subnet_ids_map = { for k, v in local.cluster_subnet_ids : v.cluster => v.subnet_id... }
  cluster_subnet_ids = toset(flatten([
    for k, v in local.cluster_subnets : {
      cluster   = v.cluster
      subnet    = v.subnet
      subnet_id = data.aws_subnet.subnet[v.subnet].id
    }
  ]))
  node_groups = toset(flatten([
    for k1, v1 in var.clusters : [
      for k2, v2 in v1.node_groups : {
        cluster               = k1
        create_security_group = v2.create_security_group
        desired_size          = v2.desired_size
        ec2_ssh_key           = v2.key_pair
        max_size              = v2.max_size
        max_unavailable       = v2.max_unavailable
        min_size              = v2.min_size
        node_group            = k2
        subnets               = v2.subnets
        tags                  = v2.tags
      }
    ]
  ]))
  node_security_group_rules = {
    egress_cluster_443 = {
      description                   = "allow HTTPS from node groups to cluster API"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "egress"
      source_cluster_security_group = true
    }
    ingress_cluster_443 = {
      description                   = "allow HTTPS from cluster API to node groups"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_kubelet = {
      description                   = "allow management from cluster API to node kubelets"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_coredns_tcp = {
      description = "allow DNS between node groups"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    egress_self_coredns_tcp = {
      description = "allow DNS between node groups"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      self        = true
    }
    ingress_self_coredns_udp = {
      description = "allow DNS between node groups"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    egress_self_coredns_udp = {
      description = "allow DNS between node groups"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "egress"
      self        = true
    }
    egress_https = {
      description = "allow HTTPS from any to internet"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_ntp_tcp = {
      description = "allow NTP from any to internet"
      protocol    = "tcp"
      from_port   = 123
      to_port     = 123
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_ntp_udp = {
      description = "allow NTP from any to internet"
      protocol    = "udp"
      from_port   = 123
      to_port     = 123
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  node_security_group_rules_object = toset(flatten([
    for k1, v1 in local.node_groups : [
      for k2, v2 in local.node_security_group_rules : {
        create_security_group = v1.create_security_group
        description           = v2.description
        name                  = k2
        node_group            = k1
        protocol              = v2.protocol
        from_port             = v2.from_port
        to_port               = v2.to_port
        type                  = v2.type
      }
    ] if v1.create_security_group == true
  ]))
  node_subnet_ids_map = { for k, v in local.node_subnet_ids : format("%s-%s", v.cluster, v.node_group) => v.subnet_id... }
  node_subnet_ids = toset(flatten([
    for k, v in local.node_subnets : {
      cluster    = v.cluster
      node_group = v.node_group
      subnet     = v.subnet
      subnet_id  = data.aws_subnet.subnet[v.subnet].id
    }
  ]))
  node_subnets_list = toset(flatten([
    for k1, v1 in local.node_groups : [
      for v2 in v1.subnets : [v2]
    ]
  ]))
  node_subnets = toset(flatten([
    for k1, v1 in local.node_groups : [
      for v2 in v1.subnets : {
        cluster    = v1.cluster
        node_group = v1.node_group
        subnet     = v2
      }
    ]
  ]))
}

output "test" {
  value = local.node_subnets_list
}

data "aws_subnet" "subnet" {
  for_each = setunion(local.cluster_subnets_list, local.node_subnets_list)

  tags = {
    Name = each.value
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

resource "aws_eks_cluster" "cluster" {
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]

  for_each = var.clusters

  name     = each.key
  role_arn = aws_iam_role.cluster[each.key].arn

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = each.value.service_cidr
  }

  vpc_config {
    endpoint_private_access = each.value.endpoint_private_access
    endpoint_public_access  = each.value.endpoint_public_access
    public_access_cidrs     = each.value.public_access_cidrs
    security_group_ids      = [aws_security_group.cluster[each.key].id]
    subnet_ids              = local.cluster_subnet_ids_map[each.key]
  }

  tags = merge(
    {
      Name              = each.key
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "aws_eks_node_group" "node_group" {
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

  for_each = { for k, v in local.node_groups : v.node_group => v }

  cluster_name    = aws_eks_cluster.cluster[each.value.cluster].name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node[each.value.cluster].arn
  subnet_ids      = local.node_subnet_ids_map[format("%s-%s", each.value.cluster, each.key)]

  remote_access {
    ec2_ssh_key               = each.value.ec2_ssh_key
    source_security_group_ids = [aws_security_group.node[each.key].id]
  }

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable = each.value.max_unavailable
  }
}

resource "aws_ecr_repository" "repository" {
  for_each = var.repositories

  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "policy" {
  for_each = var.repositories

  repository = aws_ecr_repository.repository[each.key].name
  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" : [
      {
        "Sid"       = format("%s-node", each.key),
        "Effect"    = "Allow",
        "Principal" = "*",
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
      },
      {
        "Sid"       = format("%s-remote", each.key),
        "Effect"    = "Allow",
        "Principal" = "*",
        "Action" : [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
        "Condition" = {
          "IpAddress" : {
            "aws:SourceIp" : each.value.remote_cidr
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "cluster" {
  for_each = var.clusters

  name = format("%s-eks-cluster", each.key)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "node" {
  for_each = var.clusters

  name = format("%s-eks-node", each.key)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster[each.key].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  for_each = var.clusters

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node[each.key].name
}

resource "aws_security_group" "cluster" {
  for_each = { for k, v in var.clusters : k => v if v.create_security_group == true }

  name        = format("%s-%s", var.vpc, each.key)
  description = format("%s-%s", var.vpc, each.key)
  vpc_id      = data.aws_vpc.vpc.id

  tags = merge(
    {
      Name              = format("%s-%s", var.vpc, each.key)
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "aws_security_group" "node" {
  for_each = { for k, v in local.node_groups : v.node_group => v if v.create_security_group == true }

  name        = format("%s-%s", var.vpc, each.key)
  description = format("%s-%s", var.vpc, each.key)
  vpc_id      = data.aws_vpc.vpc.id

  tags = merge(
    {
      Name              = format("%s-%s", var.vpc, each.key)
      terraform_managed = "true"
    },
    each.value.tags
  )
}

resource "aws_security_group_rule" "cluster" {
  for_each = { for k, v in local.cluster_security_group_rules_object : format("%s_%s", v.cluster, v.name) => v if v.create_security_group == true }

  security_group_id        = aws_security_group.cluster[each.value.cluster].id
  source_security_group_id = aws_security_group.cluster[each.value.cluster].id
  description              = each.value.description
  from_port                = each.value.from_port
  protocol                 = each.value.protocol
  to_port                  = each.value.to_port
  type                     = each.value.type
}