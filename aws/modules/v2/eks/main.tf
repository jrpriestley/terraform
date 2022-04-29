locals {
  cluster_subnet_ids = toset(flatten([
    for k, v in var.subnets : [data.aws_subnet.subnet[v].id]
  ]))
  node_subnet_ids_map = { for k, v in local.node_subnet_ids : v.node_group => v.subnet_id... }
  node_subnet_ids = toset(flatten([
    for k, v in local.node_subnets : {
      node_group = v.node_group
      subnet     = v.subnet
      subnet_id  = data.aws_subnet.subnet[v.subnet].id
    }
  ]))
  node_subnets_list = toset(flatten([
    for k1, v1 in var.node_groups : [
      for v2 in v1.subnets : [v2]
    ]
  ]))
  node_subnets = toset(flatten([
    for k1, v1 in var.node_groups : [
      for v2 in v1.subnets : {
        node_group = v1.name
        subnet     = v2
      }
    ]
  ]))
}

data "aws_key_pair" "key_pair" {
  for_each = { for k, v in var.node_groups : v.name => v }

  key_name = each.value.key_pair
}

data "aws_subnet" "subnet" {
  for_each = setunion(var.subnets, local.node_subnets_list)

  vpc_id = data.aws_vpc.vpc.id
  tags = {
    Name = each.value
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc
  }
}

module "security_group_cluster" {
  count = var.create_security_group == true ? 1 : 0

  security_groups = [
    {
      name                              = format("%s-%s", var.vpc, var.name)
      allow_same_security_group_traffic = true
      tags = {
      }
    },
  ]

  source = "../security_group"
  vpc    = var.vpc
}

module "security_group_node" {
  for_each = { for k, v in var.node_groups : v.name => v if var.create_security_group == true }

  security_groups = [
    {
      name                              = format("%s-%s", var.vpc, each.key)
      allow_same_security_group_traffic = true
      tags = {
      }
    },
  ]

  source = "../security_group"
  vpc    = var.vpc
}

module "security_group_rules_cluster" {
  depends_on = [
    module.security_group_cluster,
    module.security_group_node,
  ]

  for_each = { for k, v in var.node_groups : v.name => v if var.create_security_group == true }

  security_group_rules = [
    {
      security_group = format("%s-%s", var.vpc, var.name)
      ingress = [
        {
          description = "allow HTTPS from node groups to cluster API"
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          endpoints   = [format("sg:%s-%s", var.vpc, each.key)]
        },
      ],
      egress = [
        {
          description = "allow HTTPS from cluster API to node groups"
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          endpoints   = [format("sg:%s-%s", var.vpc, each.key)]
        },
        {
          description = "allow management from cluster API to node kubelets"
          protocol    = "tcp"
          from_port   = 10250
          to_port     = 10250
          endpoints   = [format("sg:%s-%s", var.vpc, each.key)]
        },
      ],
    },
  ]

  source = "../security_group_rule"
  vpc    = var.vpc
}

module "security_group_rules_node" {
  depends_on = [
    module.security_group_node,
  ]

  for_each = { for k, v in var.node_groups : v.name => v if var.create_security_group == true }

  security_group_rules = [
    {
      security_group = format("%s-%s", var.vpc, each.key)
      ingress = [
        {
          description = "allow HTTPS from cluster API to node groups"
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          endpoints   = [format("sg:%s-%s", var.vpc, var.name)]
        },
        {
          description = "allow management from cluster API to node kubelets"
          protocol    = "tcp"
          from_port   = 10250
          to_port     = 10250
          endpoints   = [format("sg:%s-%s", var.vpc, var.name)]
        },
        {
          description = "allow DNS between node groups"
          protocol    = "tcp"
          from_port   = 53
          to_port     = 53
          endpoints   = [format("sg:%s-%s", var.vpc, each.key)]
        },
        {
          description = "allow DNS between node groups"
          protocol    = "udp"
          from_port   = 53
          to_port     = 53
          endpoints   = [format("sg:%s-%s", var.vpc, each.key)]
        },
      ],
      egress = [
        {
          description = "allow HTTPS from node groups to cluster API"
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          endpoints   = [format("sg:%s-%s", var.vpc, var.name)]
        },
        {
          description = "allow DNS between node groups"
          protocol    = "tcp"
          from_port   = 53
          to_port     = 53
          endpoints   = [format("sg:%s-%s", var.vpc, each.key)]
        },
        {
          description = "allow DNS between node groups"
          protocol    = "udp"
          from_port   = 53
          to_port     = 53
          endpoints   = [format("sg:%s-%s", var.vpc, each.key)]
        },
        {
          description = "allow HTTPS from any to internet"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          endpoints   = ["cidr:0.0.0.0/0"]
        },
        {
          description = "allow NTP from any to internet"
          from_port   = 123
          to_port     = 123
          protocol    = "tcp"
          endpoints   = ["cidr:0.0.0.0/0"]
        },
        {
          description = "allow NTP from any to internet"
          from_port   = 123
          to_port     = 123
          protocol    = "udp"
          endpoints   = ["cidr:0.0.0.0/0"]
        },
      ],
    },
  ]

  source = "../security_group_rule"
  vpc    = var.vpc
}

resource "aws_eks_cluster" "cluster" {
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    module.security_group_cluster,
  ]

  name     = var.name
  role_arn = aws_iam_role.cluster[0].arn

  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = var.service_cidr
  }

  vpc_config {
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = [module.security_group_cluster[0].security_groups[format("%s-%s", var.vpc, var.name)].id]
    subnet_ids              = local.cluster_subnet_ids
  }

  tags = merge(
    {
      Name              = var.name
      terraform_managed = "true"
    },
    var.tags
  )
}

resource "aws_eks_node_group" "node_group" {
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    module.security_group_node,
  ]

  for_each = { for k, v in var.node_groups : v.name => v }

  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = local.node_subnet_ids_map[each.key]

  remote_access {
    ec2_ssh_key               = data.aws_key_pair.key_pair[each.key].key_name
    source_security_group_ids = [module.security_group_node[each.key].security_groups[format("%s-%s", var.vpc, each.key)].id]
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

resource "aws_eks_fargate_profile" "fargate" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = format("%s-fargate", var.name)
  pod_execution_role_arn = aws_iam_role.fargate[0].arn
  subnet_ids             = local.cluster_subnet_ids

  selector {
    namespace = "default"
  }

  /* commented out until I figure out how to run kube services in FarGate
  selector {
    namespace = "kube-node-lease"
  }

  selector {
    namespace = "kube-public"
  }

  selector {
    namespace = "kube-system"
  }
  */
}

resource "aws_iam_role" "cluster" {
  count = var.create_iam_role == true ? 1 : 0

  name = format("%s-cluster", var.name)
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

resource "aws_iam_role" "fargate" {
  count = var.fargate_enabled == true ? 1 : 0

  name = format("%s-fargate", var.name)
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role" "node" {
  count = var.create_iam_role == true ? 1 : 0

  name = format("%s-node", var.name)
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster[0].name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node[0].name
}