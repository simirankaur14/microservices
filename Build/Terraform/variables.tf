variable "bucket_name" {
  type    = string
  default = "shalinianjali-bucket"
}

variable "bucket_env" {
  type    = string
  default = "Dev"
}

variable "sns_topic_name" {
  type    = string
  default = "terraform_sns_topic"
}

variable "sns_emailnotify" {
  type    = string
  default = "email"
}

variable "emailid" {
  type = string
}