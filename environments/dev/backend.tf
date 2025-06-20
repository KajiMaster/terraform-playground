terraform {
  backend "s3" {
    bucket         = "tf-playground-state-vexus"
    key            = "dev-${TF_VAR_developer}/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = false # Set to false since we couldn't enable encryption
  }
} 