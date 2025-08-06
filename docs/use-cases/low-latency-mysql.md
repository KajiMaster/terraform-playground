# Low-Latency MySQL Use Case

Found this on Upwork - interesting pattern to practice in the lab.

## Requirements

### Configuration
The Terraform should support easy parameter configuration for:
- ECR URI for the application container
- S3 bucket path for database backups  
- CloudWatch log group for application container logs

### Key Objectives
Completed terraform code that creates a running EC2 instance that does the following:

**On startup:**
- Automatically restore the database to RAM disk from a local backup if available, otherwise from S3
- Start MySQL
- Start the application container

**While running:**
- Backup the database to local volume every 5 minutes
- Copy the local backup to S3 every hour
- Trim S3 backups to a 12 hour retention period
- On push to latest tag in ECR, stop, update, and restart the application container

**On shutdown:**
- Stop the application container
- Backup the database to local volume and to S3

**Monitoring:**
- CloudWatch dashboard with:
  - RAM writes
  - RAM write latency  
  - Instance CPU load
- Alerts:
  - Database size greater than 3GB
- Application container output piped to a CloudWatch log group

## Notes
- Interesting RAM disk pattern - never done MySQL on RAM disk before
- Good automation challenge with the S3 backup lifecycle
- Could be a nice contrast to our serverless work - showing EC2 optimization skills
- Lots of moving pieces but each component is pretty clear