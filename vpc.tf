# Declare the data source
data "aws_availability_zones" "all" {}

# Destination VPC with private, public subnets and 1 NAT gateway
module "destination_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_destination_name
  cidr = var.vpc_destination_cidr

  azs             = data.aws_availability_zones.all.names
  private_subnets = [cidrsubnet(var.vpc_destination_cidr, 3, 0), cidrsubnet(var.vpc_destination_cidr, 3, 1), cidrsubnet(var.vpc_destination_cidr, 3, 2)]
  public_subnets  = [cidrsubnet(var.vpc_destination_cidr, 3, 3), cidrsubnet(var.vpc_destination_cidr, 3, 4), cidrsubnet(var.vpc_destination_cidr, 3, 5)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Environment = var.environment
  }
}

# Source VPC with private, public subnets and 1 NAT gateway
module "source_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  providers = {
    aws = aws.source
  }

  name = var.vpc_source_name
  cidr = var.vpc_source_cidr

  azs             = data.aws_availability_zones.all.names
  private_subnets = [cidrsubnet(var.vpc_source_cidr, 3, 0), cidrsubnet(var.vpc_source_cidr, 3, 1), cidrsubnet(var.vpc_source_cidr, 3, 2)]
  public_subnets  = [cidrsubnet(var.vpc_source_cidr, 3, 3), cidrsubnet(var.vpc_source_cidr, 3, 4), cidrsubnet(var.vpc_source_cidr, 3, 5)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Environment = var.environment
  }
}

resource "aws_vpc_peering_connection" "pcx" {
  provider      = aws
  peer_owner_id = data.aws_caller_identity.source.account_id
  peer_vpc_id   = module.source_vpc.vpc_id
  vpc_id        = module.destination_vpc.vpc_id
  auto_accept   = false

  tags = {
    Name = var.vpc_peering_connection_name
    Side = "requester"
  }
}

resource "aws_vpc_peering_connection_options" "requester" {
  # As options can't be set until the connection has been accepted
  # create an explicit dependency on the accepter.
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.pcx_accepter.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  provider                  = aws.source
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.pcx_accepter.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_accepter" "pcx_accepter" {
  provider                  = aws.source
  vpc_peering_connection_id = aws_vpc_peering_connection.pcx.id
  auto_accept               = true

  tags = {
    Side = "accepter"
  }
}

resource "aws_route" "destination_r" {
  provider                  = aws
  count                     = 1
  route_table_id            = module.destination_vpc.private_route_table_ids[0]
  destination_cidr_block    = module.source_vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.pcx.id
  depends_on                = [aws_vpc_peering_connection.pcx,aws_vpc_peering_connection_accepter.pcx_accepter]
}

resource "aws_route" "source_r" {
  provider                  = aws.source
  count                     = 1
  route_table_id            = module.source_vpc.private_route_table_ids[0]
  destination_cidr_block    = module.destination_vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.pcx.id
  depends_on                = [aws_vpc_peering_connection.pcx,aws_vpc_peering_connection_accepter.pcx_accepter]
}
