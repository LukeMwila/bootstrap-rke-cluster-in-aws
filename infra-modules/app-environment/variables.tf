variable "profile" {
  description = "AWS profile"
  type        = string
}

variable "region" {
  description = "aws region to deploy to"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type = string
}

variable "environment" {
  description = "Application environment"
  type = string
}

variable "key_name" {
  type = string
}