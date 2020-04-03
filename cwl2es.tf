resource "aws_iam_role" "lambda_elasticsearch_execution_role" {
  provider = aws.source
  name     = "lambda_elasticsearch_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_elasticsearch_execution_policy" {
  provider = aws.source
  name     = "lambda_elasticsearch_execution_policy"
  role     = aws_iam_role.lambda_elasticsearch_execution_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "es:ESHttpPost",
      "Resource": "arn:aws:es:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_security_group" "lambda_sg" {
  provider    = aws.source
  name        = "${var.vpc_source_name}-lambda-sg"
  description = "Managed by Terraform"
  vpc_id      = module.source_vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_destination_cidr]
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/js/cwl2es.js"
  output_path = "${path.module}/.artifacts/cwl2es.zip"
}

resource "aws_lambda_function" "cwl_stream_lambda" {
  provider         = aws.source
  filename         = "${path.module}/.artifacts/cwl2es.zip"
  function_name    = "LogsToElasticsearch"
  role             = aws_iam_role.lambda_elasticsearch_execution_role.arn
  handler          = "cwl2es.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs12.x"

  vpc_config {
    subnet_ids         = module.source_vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      es_endpoint = aws_elasticsearch_domain.es.endpoint
    }
  }
}

resource "aws_lambda_permission" "cloudwatch_allow" {
  provider      = aws.source
  statement_id  = "cloudwatch_allow"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cwl_stream_lambda.arn
  principal     = "logs.${var.aws_region}.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.lambda_log_group.arn
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_logs_to_es" {
  provider        = aws.source
  name            = "cloudwatch_logs_to_elasticsearch"
  log_group_name  = aws_cloudwatch_log_group.lambda_log_group.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.cwl_stream_lambda.arn
  depends_on      = [aws_lambda_permission.cloudwatch_allow]
}
