terraform {
  backend "s3" {
    bucket         = "terraformbucketremotebackend"
    key            = "Terraform_State_files/terraform.tfstate" # Define a unique path for state files
    region         = "us-east-1"
    dynamodb_table = "remotebackend" # Optional for state locking
  }
}


resource "aws_s3_bucket" "shalinianjali" {
  bucket = "shalinianjali-bucket"

  tags = {
    Name        = "My bucket"
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
  handler       = "lambda_function.lambda_function.lambda_handler"
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






