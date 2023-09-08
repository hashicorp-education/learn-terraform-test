variable "bucket_name" {
  description = "Name of the s3 bucket. Must be unique."
  default     = null
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 10
    error_message = "The bucket name must be 10 characters or longer."
  }
}