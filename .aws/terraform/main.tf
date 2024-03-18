module "namespace" {
  source = "./modules/namespace"
  repo = var.repo
  environment = var.environment
  branch = var.branch
}
