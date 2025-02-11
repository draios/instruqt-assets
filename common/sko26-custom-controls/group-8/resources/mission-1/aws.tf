resource "aws_lambda_function" "this" {
  function_name = "sko-2026-lambda-${var.group_id}"
  description   = "Lambda function triggered by SQS"
  runtime       = "python3.8"
  handler       = "lambda_function.lambda_handler"
  memory_size   = 128
  publish       = true
  role          = aws_iam_role.this.arn
}

resource "aws_iam_role" "this" {
  name = "sko-2026-lambda-role-${var.group_id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}