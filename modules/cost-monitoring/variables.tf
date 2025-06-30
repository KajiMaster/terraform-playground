variable "environment" {
  description = "Environment name"
  type        = string
}

variable "daily_budget_limit" {
  description = "Daily budget limit in USD"
  type        = number
  default     = 10.0
}

variable "alert_email_addresses" {
  description = "List of email addresses to receive cost alerts"
  type        = list(string)
  default     = []
}

variable "after_hours_check_time" {
  description = "Time to check for after-hours usage (UTC, 24-hour format)"
  type        = string
  default     = "20:00" # 8 PM UTC
} 