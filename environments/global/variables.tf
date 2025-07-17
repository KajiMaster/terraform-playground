# Global environment variables
# These control shared resources across all environments

variable "enable_waf" {
  description = "Enable WAF globally (affects all environments)"
  type        = bool
  default     = false  # Disabled by default for cost optimization
}

variable "enable_logging" {
  description = "Enable WAF logging to S3"
  type        = bool
  default     = false  # Disabled when WAF is disabled
}

variable "waf_rate_limit" {
  description = "Rate limit for requests per IP (requests per 5 minutes)"
  type        = number
  default     = 1000
}

variable "enable_ip_reputation" {
  description = "Enable AWS IP reputation list rule"
  type        = bool
  default     = true
}

variable "waf_blocked_paths" {
  description = "Comma-separated list of paths to block (e.g., '/admin,/internal')"
  type        = string
  default     = null
}

variable "waf_log_retention_days" {
  description = "Number of days to retain WAF logs"
  type        = number
  default     = 7
} 