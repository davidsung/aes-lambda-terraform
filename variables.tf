variable "environment" {
  description = "Environment"
  default = "staging"
}

variable "aws_region" {
  default = "ap-southeast-1"
}

variable "aws_destination_profile" {
  description = "AWS Credentials for the Destination Profile"
}

variable "aws_source_profile" {
  description = "AWS Credentials Profile"
}

// Destination VPC
variable "vpc_destination_name" {
  description = "VPC Name"
}

variable "vpc_destination_cidr" {
  description = "VPC CIDR block"
}

// Source VPC
variable "vpc_source_name" {
  description = "VPC Name"
}

variable "vpc_source_cidr" {
  description = "VPC CIDR block"
}

// VPC Peering
variable "vpc_peering_connection_name" {
  description = "VPC Peering Connection Name"
}

// Elasticsearch
variable "es_version" {
  description = "ES Version"
  default = "7.4"
}

variable "es_domain" {
  description = "ES Domain"
}

variable "es_instance_type" {
  description = "ES Instance Type"
  default = "r5.large.elasticsearch"
}

variable "es_encrypt_at_rest_enabled" {
  description = "ES Encrypt At Rest"
  default = true
}

variable "es_volume_type" {
  description = "ES EBS volume type"
  default = "gp2"
}

variable "es_volume_size" {
  description = "ES EBS volume size in GB"
}

variable "es_snapshot_start_hour" {
  description = "ES Snapshot Start Hour"
}

variable "es_dedicated_master_enabled" {
  description = "ES Dedicated Master Node"
  default = false
}

variable "es_dedicated_master_type" {
  description = "ES Dedicated Master Instance Type"
  default = ""
}

variable "es_enforce_https" {
  description = "ES Enforce HTTPS"
  default = true
}

variable "es_tls_security_policy" {
  description = "ES TLS Security Policy"
  default = "Policy-Min-TLS-1-2-2019-07"
}

variable "es_node_to_node_encryption_enabled" {
  description = "Elasticsearch Node to Node Encryption"
  default = true
}
