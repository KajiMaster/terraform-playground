# Empty S3 backend block to suppress warnings
# This does nothing - actual backend configuration is provided via:
# - backend-dev.hcl
# - backend-staging.hcl  
# - backend-production.hcl
# These files supersede this block with real values for bucket, key, region, etc.

terraform {
  backend "s3" {
    # All values provided via -backend-config=backend-{env}.hcl
  }
}