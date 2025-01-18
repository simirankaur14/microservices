terraform {
  backend "s3" {
    bucket         = "terraformbucketremotebackend"
    key            = "Terraform_State_files/terraform.tfstate" # Define a unique path for state files
    region         = "us-east-1"
    dynamodb_table = "remotebackend" # Optional for state locking
  }
}


resource "aws_s3_bucket" "shalinianjali" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = "Dev"
  }
}


/*
#creating a s3 bucket
resource "aws_s3_bucket" "shalinianjali" {
  bucket = "shalinianjali-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
*/


#creating a sns notification 
resource "aws_sns_topic" "user_updates" {
  name            = "terraform_sns_topic"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}


resource "aws_sns_topic_policy" "sns_policy" {
  arn = aws_sns_topic.user_updates.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.user_updates.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn": aws_s3_bucket.shalinianjali.arn
          }
        }
      }
    ]
  })
}


#creating a sns notification subscription [email]
resource "aws_sns_topic_subscription" "user_updates_sns_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "simiranjeet.kaur@hcl.software"
}


resource "aws_lambda_function" "test_lambda" {
  filename      = "./lambda_function_folder.zip"
  function_name = "test_name"
  role          = "arn:aws:iam::816069139413:role/lambdarole"
  handler       = "lambda_function.lambda_handler"
  runtime = "python3.9"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

#creating a s3 event bucket notifications
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.shalinianjali.id

  topic {
    topic_arn     = aws_sns_topic.user_updates.arn
    events        = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_sns_topic.user_updates , aws_s3_bucket.shalinianjali]
}

# creating  a sqs notification 
resource "aws_sqs_queue" "terraform_queue" {
  name                      = "terraform-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10


  tags = {
    Environment = "production"
  }
}

resource "aws_instance" "ec2_instances" {
  for_each = toset(var.ec2_instance_name)

  ami           =  "ami-05576a079321f21f8" # Replace with your desired AMI ID 
  instance_type = "t2.micro"             # Update with your desired instance type
  key_name      = "test"        # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.ansible_master_sg.id]

  tags = {
    Name = each.key
  }
}

resource "aws_security_group" "ansible_master_sg" {
  name        = "ansible_master_sg"
  description = "Security group for Ansible master"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH access from anywhere (adjust for security)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

# Stepfunction Block
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = "arn:aws:iam::816069139413:role/stepfunction_lambdaaccess_role"

  definition = file("${path.module}/defination.yaml")
}

# APIGATEWAY Block

resource "aws_api_gateway_rest_api" "MyDemoAPI" {
  name        = "MyDemoAPI"
  description = "This is my API for demonstration purposes"
}

resource "aws_api_gateway_resource" "MyDemoResource" {
  rest_api_id = aws_api_gateway_rest_api.MyDemoAPI.id
  parent_id   = aws_api_gateway_rest_api.MyDemoAPI.root_resource_id
  path_part   = "test"
  depends_on = [ aws_api_gateway_rest_api.MyDemoAPI ]
}

resource "aws_api_gateway_method" "MyDemoMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyDemoAPI.id
  resource_id   = aws_api_gateway_resource.MyDemoResource.id
  http_method   = "GET"
  authorization = "NONE"
  depends_on = [ aws_api_gateway_rest_api.MyDemoAPI ,aws_api_gateway_resource.MyDemoResource ]
}


resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.MyDemoAPI.id
  resource_id             = aws_api_gateway_resource.MyDemoResource.id
  http_method             = aws_api_gateway_method.MyDemoMethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
  depends_on = [ aws_api_gateway_rest_api.MyDemoAPI , aws_api_gateway_method.MyDemoMethod ,aws_api_gateway_resource.MyDemoResource ,aws_lambda_function.test_lambda  ]
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  depends_on = [ aws_api_gateway_rest_api.MyDemoAPI , aws_api_gateway_method.MyDemoMethod ,aws_api_gateway_resource.MyDemoResource, aws_api_gateway_integration.integration, aws_lambda_function.test_lambda   ]
  #source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}


