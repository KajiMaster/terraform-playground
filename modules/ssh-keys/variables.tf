variable "environment" {
  description = "Environment name for the key pair"
  type        = string
}

variable "ssh_private_key_secret_name" {
  description = "Name of the secret containing the SSH private key"
  type        = string
  default     = "/tf-playground/all/ssh-key"
}

variable "ssh_public_key_secret_name" {
  description = "Name of the secret containing the SSH public key"
  type        = string
  default     = "/tf-playground/all/ssh-key-public"
} 