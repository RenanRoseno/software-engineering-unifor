variable "aws_region" {
  description = "AWS region for the blood registry platform"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix used for all cloud resources"
  type        = string
  default     = "blood-registry"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "db_username" {
  description = "Primary database username"
  type        = string
  default     = "registry_app"
  sensitive   = true
}

variable "db_password" {
  description = "Primary database password"
  type        = string
  default     = "change_me"
  sensitive   = true
}

variable "jwt_issuer_uri" {
  description = "OIDC/JWT issuer URI for the identity gateway"
  type        = string
  default     = "http://localhost:8080/realms/blood-registry"
}

variable "redis_node_type" {
  description = "Redis cache node size"
  type        = string
  default     = "cache.t3.micro"
}

variable "alert_email" {
  description = "Operational alert recipient address"
  type        = string
  default     = "ops@example.com"
}
