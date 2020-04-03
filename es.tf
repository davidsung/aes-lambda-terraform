resource "aws_security_group" "es" {
  name        = "${var.vpc_destination_name}-elasticsearch-${var.es_domain}"
  description = "Managed by Terraform"
  vpc_id      = module.destination_vpc.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      module.destination_vpc.vpc_cidr_block
    ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      var.vpc_source_cidr
    ]
  }
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.es_domain
  elasticsearch_version = var.es_version

  cluster_config {
    dedicated_master_enabled = var.es_dedicated_master_enabled
    dedicated_master_type    = var.es_dedicated_master_type
    instance_type            = var.es_instance_type
  }

  vpc_options {
    subnet_ids         = [module.destination_vpc.private_subnets[0]]
    security_group_ids = [aws_security_group.es.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_type = var.es_volume_type
    volume_size = var.es_volume_size
  }

  encrypt_at_rest {
    enabled = var.es_encrypt_at_rest_enabled
  }

  snapshot_options {
    automated_snapshot_start_hour = var.es_snapshot_start_hour
  }

  domain_endpoint_options {
    enforce_https = var.es_enforce_https
    tls_security_policy = var.es_tls_security_policy
  }

  node_to_node_encryption {
    enabled = var.es_node_to_node_encryption_enabled
  }

  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "es:*",
      "Principal": "*",
      "Effect": "Allow",
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.es_domain}/*"
    }
  ]
}
POLICY

  tags = {
    Environment = var.environment
    Domain = var.es_domain
  }

  depends_on = [aws_iam_service_linked_role.es]
}
