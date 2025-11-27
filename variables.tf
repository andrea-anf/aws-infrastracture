variable "app_port" {
  type        = number
  default     = 3000
  description = "Port used by the application"
}

variable "project" {
  type        = string
  default     = "sample-app"
  description = "The project name"
}

variable "cpu" {
  type        = number
  default     = 256
  description = "CPU used by tasks"
}

variable "memory" {
  type        = number
  default     = 512
  description = "RAM used by tasks"
}
