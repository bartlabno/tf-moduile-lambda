# Default variables
variable "tag_version" {}

variable "environment" {
  type        = string
  description = "The name of the environment in which this module is being invoked"
  validation {
    condition     = contains(["dev", "preprod", "prod"], var.environment)
    error_message = "Environment name must be one of known names."
  }
}

variable "project_name" {}

variable "vpc_id" {
  type        = string
  description = "VPC in which to create resources"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to be applied to all resources created by this module"
  default     = {}
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to execute the lambda in"
}

variable "iam_policy_additional" {
  type        = string
  description = "Additional IAM policies to also attach to IAM role"
  default     = null
}

variable "cron_expression" {
  type        = string
  description = "Cron expression - optional use for function to be used alongside eventbridge."
  default     = null
}

variable "cron_invocation_inputs" {
  type        = list(string)
  description = "Payload to pass to lambda - if multiple payloads submitted, lambda will execute in parallel once per payload"
  default     = null
}

variable "cron_rule_enabled" {
  type        = bool
  description = "Whether to enable the rule created by cron_expression"
  default     = true
}

variable "error_pattern" {
  type        = string
  description = "A pattern which when found in the log group will produce an alarm"
  default     = null
}

variable "timeout" {
  type        = number
  description = "The lambda timeout in seconds"
}

variable "memory_size_mb" {
  type        = number
  description = "The lambda memory size in megabytes"
  default     = 128
}

variable "environment_vars" {
  type        = map(string)
  description = "Variables that the executing function can use"
  default     = null
}

variable "filename" {
  type        = string
  description = "Deployment package (zip) as a local file"
  default     = null
}

variable "s3_bucket" {
  type        = string
  description = "S3 bucket location"
  default     = null
}

variable "s3_key" {
  type        = string
  description = "S3 key of the object containing deployment package"
  default     = null
}

variable "image_uri" {
  type        = string
  description = "ECR image URI containing the function's deployment package"
  default     = null
}

variable "local_code_dir" {
  type        = string
  description = "Local directory containing the function's deployment code, to be packaged and deployed"
  default     = null
  validation {
    condition = (
      var.local_code_dir == null || can(regex("^.*[^/]$", var.local_code_dir))
    )
    error_message = "No trailing slash on the directory name."
  }
}

variable "runtime" {
  type        = string
  description = "Lambda runtime to use - required for all types except image_uri"
  default     = null
}

variable "handler" {
  type        = string
  description = "Entry point in function - required for all types except image_uri"
  default     = null
}

variable "image_update_on_push" {
  type        = string
  description = "Automatically update the lambda when a new image is pushed to the repo"
  default     = false
}

variable "architecture" {
  type        = string
  description = "Deployment package (zip) as a local file"
  default     = "x86_64"
  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "Architecture must be either x86_64 or arm64."
  }
}
