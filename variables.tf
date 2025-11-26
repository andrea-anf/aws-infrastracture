variable "app_port" {
  type        = number
  default     = 3000
  description = "Port used by the application"
}

variable "project" {
  type        = string
  default     = "project-name"
  description = "The project name"
}
