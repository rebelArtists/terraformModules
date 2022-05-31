variable "dynamo_table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
}

variable "state_bucket_name" {
  description = "s3 bucket name that stores db state file"
}

variable "state_file_key" {
  description = "state file key name in s3"
}
