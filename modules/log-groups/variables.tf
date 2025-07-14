variable "log_retention_days" {
  description = "Number of days to retain logs (demo: 1 day)"
  type        = number
  default     = 1
}

variable "environments" {
  description = "List of environments to create log groups for"
  type        = list(string)
  default     = ["dev", "staging", "production"]
} 