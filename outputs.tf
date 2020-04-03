output "vpc_id" {
  value = module.destination_vpc.vpc_id
}

output "es_endpoint" {
  value = aws_elasticsearch_domain.es.endpoint
}

output "kibana_endpoint" {
  value = aws_elasticsearch_domain.es.kibana_endpoint
}

output "base_url" {
  value = aws_api_gateway_deployment.apigw_deployment.invoke_url
}
