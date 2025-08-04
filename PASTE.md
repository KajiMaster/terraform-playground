
│ Error: Get "http://localhost/api/v1/namespaces/default/secrets/db-password": dial tcp [::1]:80: connect: connection refused
│ 
│   with kubernetes_secret.db_password[0],
│   on main.tf line 319, in resource "kubernetes_secret" "db_password":
│  319: resource "kubernetes_secret" "db_password" {
│ 
╵
╷
│ Error: Get "http://localhost/api/v1/namespaces/default/services/dev-flask-app-service": dial tcp [::1]:80: connect: connection refused
│ 
│   with kubernetes_service.flask_app[0],
│   on main.tf line 416, in resource "kubernetes_service" "flask_app":
│  416: resource "kubernetes_service" "flask_app" {