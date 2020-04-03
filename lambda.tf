# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  provider    = aws.source
  name        = "api"
  description = "This is a pseudo api for demonstration purposes"
}

resource "aws_api_gateway_method" "apigw_method" {
  provider      = aws.source
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "apigw_integration" {
  provider    = aws.source
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_method.apigw_method.resource_id
  http_method = aws_api_gateway_method.apigw_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.index_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "apigw_deployment" {
  provider    = aws.source
  depends_on  = [aws_api_gateway_integration.apigw_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  provider      = aws.source
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.index_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_iam_role" "iam_for_lambda" {
  provider = aws.source
  name     = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "index_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/js/index.js"
  output_path = "${path.module}/.artifacts/index.zip"
}

resource "aws_lambda_function" "index_lambda" {
  provider         = aws.source
  filename         = "${path.module}/.artifacts/index.zip"
  function_name    = "lambda"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.index_lambda_zip.output_base64sha256
  runtime          = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  provider          = aws.source
  name              = "/aws/lambda/${aws_lambda_function.index_lambda.function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  provider    = aws.source
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  provider   = aws.source
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}
