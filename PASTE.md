module.logging.aws_cloudwatch_metric_alarm.slow_response_time: Modifications complete after 3s [id=slow-response-time-dev]
╷
│ Error: putting CloudWatch Dashboard (tf-playground-dev): operation error CloudWatch: PutDashboard, https response error StatusCode: 400, RequestID: 2c697ed2-d6ae-44a2-9d7e-093e09c38e75, InvalidParameterInput: The dashboard body is invalid, there are 3 validation errors:
│ [
│   {
│     "dataPath": "/widgets/0/properties/metrics/1",
│     "message": "Should NOT have more than 3 items"
│   },
│   {
│     "dataPath": "/widgets/0/properties/metrics/2",
│     "message": "Should NOT have more than 3 items"
│   },
│   {
│     "dataPath": "/widgets/0/properties/metrics/3",
│     "message": "Should NOT have more than 3 items"
│   }
│ ]
│ 
│   with module.logging.aws_cloudwatch_dashboard.main,
│   on ../../modules/logging/main.tf line 20, in resource "aws_cloudwatch_dashboard" "main":
│   20: resource "aws_cloudwatch_dashboard" "main" {
│ 
╵