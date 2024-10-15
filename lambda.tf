#Lambda function creation
resource "aws_lambda_function" "lambda_function" {
  function_name = "$func-${local.suffix}"

  image_uri        = var.image_uri
  filename         = var.local_code_dir != null && var.s3_bucket == null ? data.archive_file.local_package[0].output_path : var.filename
  s3_bucket        = var.s3_bucket
  s3_key           = var.local_code_dir != null && var.s3_bucket != null ? aws_s3_object.package_upload[0].key : var.s3_key
  package_type     = var.image_uri == null ? "Zip" : "Image"
  source_code_hash = var.local_code_dir != null ? data.archive_file.local_package[0].output_base64sha256 : (var.filename != null ? filebase64sha256(var.filename) : null)

  role          = aws_iam_role.lambda-iam-role.arn
  runtime       = var.runtime
  handler       = var.handler
  timeout       = var.timeout
  memory_size   = var.memory_size_mb
  architectures = [var.architecture]

  # Only create the environment block if needed - terraform shows a continual difference if it's unset (bug)
  dynamic "environment" {
    for_each = var.environment_vars == null ? [] : [1]
    content {
      variables = var.environment_vars
    }
  }

  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = [
      aws_security_group.lambda_sg.id
    ]
  }

  lifecycle {
    replace_triggered_by = [aws_security_group.lambda_sg] # If the security group needs to be replaced, the lambda must be removed so its EIPs can be disassociated from the SG
    # NOTE: this is over-zealous - it replaces the function and related things on every minor change (e.g. tagging) - but it is necessary
  }

  tags = merge(
    var.tags,
    var.image_update_on_push && var.image_uri != null ? { UpdateOnEcrPush = "yes" } : {}
  )
}

#Lambda Security Group
resource "aws_security_group" "lambda_sg" {
  name   = "lambda-sg-${local.suffix}"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    { Name = "lambda-sg-${local.suffix}" }
  )
}

# Lambda IAM role creation
resource "aws_iam_role" "lambda-iam-role" {
  name = trim(substr("iam-role-lambda-${local.suffix}", 0, 64), "-")
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = ["sts:AssumeRole"]
          Principal = {
            Service = ["lambda.amazonaws.com"]
          }
        }
      ]
    }
  )
}

# AWS issued policy for Lambda role
resource "aws_iam_role_policy_attachment" "att_pol_lambda" {
  role       = aws_iam_role.lambda-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Optional extra permissions if supplied
resource "aws_iam_policy" "policy_additional" {
  count  = var.iam_policy_additional == null ? 0 : 1
  name   = "iam-add-pol-lambda-${local.suffix}"
  policy = var.iam_policy_additional
}

resource "aws_iam_role_policy_attachment" "att_add_pol_lambda" {
  count      = var.iam_policy_additional == null ? 0 : 1
  role       = aws_iam_role.lambda-iam-role.name
  policy_arn = aws_iam_policy.policy_additional[0].arn
}

resource "random_id" "version" {
  byte_length = 2

  # Nicer would be to use this resource's `keepers` attribute, but there's nothing in the lambda with which it can be associated (e.g. source_code_hash would not change if the lambda is replaced for other reasons)
  lifecycle {
    replace_triggered_by = [aws_lambda_function.lambda_function]
  }
}