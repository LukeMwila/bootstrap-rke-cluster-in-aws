# VPC
module "vpc_for_kubernetes_cluster" {
  source = "./vpc"
  cluster_name = var.cluster_name
  vpc_tag_name = "${var.cluster_name}-vpc"
  route_table_tag_name = "${var.cluster_name}-rt"
  # nlb_name = "${var.cluster_name}-nlb"
  region = var.region
  environment = var.environment
}

# K8s Cluster Control Plane
module "control_plane_for_kubernetes_cluster" {
  depends_on = [
    module.vpc_for_kubernetes_cluster
  ]
  source = "./cluster-asg"
  cluster_name = var.cluster_name
  name_prefix = "k8s-control-plane-01"
  launch_template_tag = "k8s-control-plane-ec2-instance"
  asg_tag = "K8s Control Plane"
  instance_profile_name = "control_plane_profile"
  vpc_id = module.vpc_for_kubernetes_cluster.vpc_id
  private_subnet_ids = module.vpc_for_kubernetes_cluster.private_subnet_ids
  public_subnet_ids = []
  launch_template_security_group_ids = [
    module.vpc_for_kubernetes_cluster.control_plane_sg_security_group_id,
    # module.vpc_for_kubernetes_cluster.public_subnet_security_group_id
  ]
  # target_group_arn = module.vpc_for_kubernetes_cluster.target_group_arn
  environment = var.environment
  desired_capacity = 3
  max_size = 6
  min_size = 3
  user_data = "master_userdata.sh"
  key_name = var.key_name
}

# K8s Cluster Worker Nodes
module "worker_nodes_for_kubernetes_cluster" {
  depends_on = [
    module.vpc_for_kubernetes_cluster,
    module.control_plane_for_kubernetes_cluster
  ]
  source = "./cluster-worker-asg"
  cluster_name = var.cluster_name
  name_prefix   = "k8s-worker-nodes"
  launch_template_tag = "k8s-worker-nodes-ec2-instance"
  asg_tag = "K8s Worker Nodes"
  instance_profile_name = "worker_nodes_profile"
  vpc_id = module.vpc_for_kubernetes_cluster.vpc_id
  private_subnet_ids = module.vpc_for_kubernetes_cluster.private_subnet_ids
  public_subnet_ids = []
  launch_template_security_group_ids = [
    module.vpc_for_kubernetes_cluster.data_plane_sg_security_group_id
  ]
  environment = var.environment
  desired_capacity = 3
  max_size = 6
  min_size = 3
  user_data = "worker_userdata.sh"
  key_name = var.key_name
}

# K8s Bastion Host
module "bastion_host_for_kubernetes_cluster" {
  depends_on = [
    module.vpc_for_kubernetes_cluster,
    module.control_plane_for_kubernetes_cluster,
    module.worker_nodes_for_kubernetes_cluster
  ]
  source = "./bastion-asg"
  cluster_name = var.cluster_name
  name_prefix   = "k8s-bastion-host"
  launch_template_tag = "k8s-bastion-host-ec2-instance"
  asg_tag = "K8s Bastion Hosts"
  instance_profile_name = "bastion_host_profile"
  vpc_id = module.vpc_for_kubernetes_cluster.vpc_id
  private_subnet_ids = module.vpc_for_kubernetes_cluster.private_subnet_ids
  public_subnet_ids = module.vpc_for_kubernetes_cluster.public_subnet_ids
  launch_template_security_group_ids = [
    module.vpc_for_kubernetes_cluster.public_subnet_security_group_id
  ]
  environment = var.environment
  desired_capacity = 1
  max_size = 6
  min_size = 1
  user_data = "bastion_userdata.sh"
  key_name = var.key_name
}