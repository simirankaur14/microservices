variable "bucket_name" {
  type    = string
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

variable "ec2_instance_name" {
type = list(string)
default = ["ansible_master" , "ansible_client_1" , "ansible_client_2"]
}
