locals {
  repo = var.repo
  environment = var.environment
  branch = var.branch
  namespace = lower("${local.repo}-${local.environment}-${replace(local.branch, "/", "-")}")
  tags = {
    "repo" : local.repo,
    "environment" : local.environment,
    "branch" : local.branch,
  }
}