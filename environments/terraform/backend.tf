terraform {
  backend "s3" {
    bucket         = "tf-playground-state-vexus"
    key            = "workspaces/terraform-staging.tfstate"
    region         = "us-east-2"
    dynamodb_table = "tf-playground-locks"
    encrypt        = false
  }
}
