terraform {
  backend "s3" {
    bucket         = "tf-playground-state-vexus"
    key            = "staging/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = false
  }
} 