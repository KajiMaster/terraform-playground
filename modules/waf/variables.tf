variable "enable_waf" {
  description = "Enable WAF creation"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable WAF logging to S3"
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "Rate limit for requests per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "enable_ip_reputation" {
  description = "Enable AWS IP reputation list rule"
  type        = bool
  default     = true
}

variable "blocked_paths" {
  description = "Comma-separated list of paths to block (e.g., '/admin,/internal')"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain WAF logs"
  type        = number
  default     = 7
} 