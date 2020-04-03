# Stream CloudWatch Log to Amazon Elasticsearch across multiple AWS Accounts

## Architecture Diagram

## Prepare terraform.tfvars
```shell script
cp example.tfvars terraform.tfvars
```
Edit `terraform.tfvars` and supply the suitable values for
* `aws_destination_profile` - AWS Profile Name where Amazon Elasticsearch should provision and
* `aws_source_profile` - AWS Profile Name where the Lambda, CloudWatch Log should provision

## Terraform dependency
```shell script
terraform init
```

## Provisioning
```shell script
terraform plan
terraform apply
```

## Endpoints
```shell script
terraform output
```

## Test
Trigger some API calls
```shell script
for i in `seq 1 5`; do curl $(terraform output base_url); done
```
Open a browser and visit the url `$(terraform output kibana_endpoint)`