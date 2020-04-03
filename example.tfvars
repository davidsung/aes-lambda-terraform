// Please specify the Destination AWS Profile (where the AES stands up)
aws_destination_profile = "destination-profile-name"
// Please specify the Source AWS Profile (where the Lambda stands up)
aws_source_profile = "source-profile-name"

environment = "staging"
aws_region = "ap-southeast-1"

// Destination VPC
vpc_destination_name = "aes-vpc"
vpc_destination_cidr = "10.0.0.0/16"

// Souce VPC
vpc_source_name = "lambda-vpc"
vpc_source_cidr = "10.1.0.0/16"

// VPC Peering
vpc_peering_connection_name = "pcx-aes-lambda"

// Elasticsearch
es_domain = "aes"
es_encrypt_at_rest_enabled = true
es_volume_type = "gp2"
es_volume_size = "10"
es_snapshot_start_hour = "20"
es_dedicated_master_enabled = false
es_node_to_node_encryption_enabled = true
es_enforce_https = true
