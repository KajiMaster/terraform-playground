# Universal S3 backend configuration
# Workspaces handle environment separation via state paths:
# - env:/dev/terraform.tfstate
# - env:/staging/terraform.tfstate  
# - env:/production/terraform.tfstate

terraform {
  backend "s3" {
    bucket         = "tf-playground-state-vexus"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = false
  }
}