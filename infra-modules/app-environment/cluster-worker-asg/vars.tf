variable ec2_instance_type {
  type        = string
  default     = "t3.medium"
  description = "EC2 host instance types"
}

variable name_prefix {
  type        = string
  description = "ASG EC2 Name prefix"
}

variable asg_tag {
  type        = string
  description = "ASG Tag name"
}

variable launch_template_tag {
  type        = string
  description = "ASG Tag name"
}

variable user_data {
  type        = string
  description = "EC2 user data"
}

variable desired_capacity {
  type        = number
  description = "Desired capacity for ASG"
}

variable max_size {
  type        = number
  description = "Max capacity for ASG"
}

variable min_size {
  type        = number
  description = "Min capacity for ASG"
}

variable instance_profile_name {
  type        = string
  default     = "k8s_control_plane_profile"
  description = "Name of the EC2 instance profile"
}

variable "availability_zones" {
  type  = list(string)
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  description = "List of availability zones for the selected region"
}

variable vpc_id {
  type        = string
  description = "ID of the custom VPC that the resources are deployed in"
}

variable "environment" {
  type        = string
  description = "Application enviroment"
}

variable private_subnet_ids {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "public_subnet_ids" {
  type = list(string)
  description = "Private subnet IDs"
}

variable launch_template_security_group_ids {
  type        = list(string)
  description = "Launch template SGs"
}

variable "cluster_name" {
  description = "The name of the cluster"
  type = string
}

variable "key_name" {
  type = string
}