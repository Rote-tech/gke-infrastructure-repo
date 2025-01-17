/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  description = [for item in module.create-vpc.network.subnets : item.description]
  gateway_address = [for item in module.create-vpc.network.subnets : item.gateway_address]
  id = [for item in module.create-vpc.network.subnets : item.id]
  ip_cidr_range = [for item in module.create-vpc.network.subnets : item.ip_cidr_range]
  name = [for item in module.create-vpc.network.subnets : item.name]
  network = [for item in module.create-vpc.network.subnets : item.network]
  private_ip_google_access = [for item in module.create-vpc.network.subnets : item.private_ip_google_access]
  project = [for item in module.create-vpc.network.subnets : item.project]
  region = [for item in module.create-vpc.network.subnets : item.region]
  secondary_ip_range =  [for item in module.create-vpc.network.subnets : [ for i in item.secondary_ip_range : { ip_cidr_range =  i.ip_cidr_range  , range_name =  i.range_name } ] ]
  self_link = [for item in module.create-vpc.network.subnets : item.self_link]
  subnet1 = {description = local.description[0] , gateway_address = local.gateway_address[0], id = local.id[0] ,ip_cidr_range = local.ip_cidr_range[0], name = local.name[0] , network = local.network[0] , private_ip_google_access = local.private_ip_google_access[0] , project = local.project[0] , region = local.region[0] , self_link = local.self_link[0] , secondary_ip_range = local.secondary_ip_range[0]  }
  subnet2 = {description = local.description[1] , gateway_address = local.gateway_address[1], id = local.id[1] ,ip_cidr_range = local.ip_cidr_range[1], name = local.name[1] , network = local.network[1] , private_ip_google_access = local.private_ip_google_access[1] , project = local.project[1] , region = local.region[1] , self_link = local.self_link[1] , secondary_ip_range = local.secondary_ip_range[1]  }
  gke_cluster_id_1 = format("projects/%s/locations/%s/clusters/%s",module.create-gcp-project.project.project_id,module.create_gke_1.cluster_name.location,module.create_gke_1.cluster_name.name)
  gke_cluster_id_2 = format("projects/%s/locations/%s/clusters/%s",module.create-gcp-project.project.project_id,module.create_gke_2.cluster_name.location,module.create_gke_2.cluster_name.name)
}

module "create-gcp-project" {
  source = "git::https://github.com/Rote-tech/terraform-modules.git//project/"
  base_project_name = var.base_project_name
  billing_account = var.billing_account
  org_id = var.org_id
  folder_id = var.folder_id
  env = var.env
  addtl_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "gkehub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "anthosconfigmanagement.googleapis.com"]
}

module "create-vpc" {
  source = "git::https://github.com/Rote-tech/terraform-modules.git//vpc/"
  project_id   = module.create-gcp-project.project.project_id
  network_name    = var.network_name
  routing_mode    = var.routing_mode
  subnet_01_name      = var.subnet_01_name
  subnet_01_ip        = var.subnet_01_ip
  subnet_01_region    = var.subnet_01_region
  subnet_01_description      = var.subnet_01_description
  subnet_02_name      = var.subnet_02_name
  subnet_02_ip        = var.subnet_02_ip
  subnet_02_region    = var.subnet_02_region
  subnet_02_description      = var.subnet_02_description
  subnet_01_secondary_svc_1_name    = var.subnet_01_secondary_svc_1_name
  subnet_01_secondary_svc_1_range = var.subnet_01_secondary_svc_1_range
  subnet_01_secondary_svc_2_name    = var.subnet_01_secondary_svc_2_name
  subnet_01_secondary_svc_2_range = var.subnet_01_secondary_svc_2_range
  subnet_01_secondary_pod_name    = var.subnet_01_secondary_pod_name
  subnet_01_secondary_pod_range = var.subnet_01_secondary_pod_range
  subnet_02_secondary_svc_1_name    = var.subnet_02_secondary_svc_1_name
  subnet_02_secondary_svc_1_range = var.subnet_02_secondary_svc_1_range
  subnet_02_secondary_svc_2_name    = var.subnet_02_secondary_svc_2_name
  subnet_02_secondary_svc_2_range = var.subnet_02_secondary_svc_2_range
  subnet_02_secondary_pod_name    = var.subnet_02_secondary_pod_name
  subnet_02_secondary_pod_range = var.subnet_02_secondary_pod_range
}

# Create GKE zonal cluster in platform_admin project using subnet-01 zone a
module "create_gke_1" {
  source            = "git::https://github.com/Rote-tech/terraform-modules.git//gke/"
  subnet            = (local.subnet1.region ==  var.subnet_01_region) ? local.subnet1 : local.subnet2
  project_id        = module.create-gcp-project.project.project_id
  suffix            = "1"
  zone              = ["a","b","c"]
  env               = var.env
  project_number    = module.create-gcp-project.project.project_number
  depends_on        = [ module.create-vpc ]
}

module "create_gke_2" {
  source            = "git::https://github.com/Rote-tech/terraform-modules.git//gke/"
  subnet            = (local.subnet2.region ==  var.subnet_02_region) ? local.subnet2 : local.subnet1
  project_id        = module.create-gcp-project.project.project_id
  suffix            = "2"
  zone              = ["a","b","c"]
  env               = var.env
  project_number    = module.create-gcp-project.project.project_number
  depends_on        = [ module.create-vpc ]
}

module "deploy-cloud-function" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//cloud-functions/grant-deploy-access"
  project_id            = module.create-gcp-project.project.project_id
  function_name         = "add-deploy-permission-${var.env}"
  function_gcs          = "add-deploy-permission-${var.env}-src"
  trigger_gcs           = "add-deploy-permission-${var.env}-trg"
  region                = var.subnet_01_region
  app_factory_project   = var.app_factory_project_num
  secrets_project_id    = var.secrets_project_id
  infra_project_id      = var.project_id
  env                   = var.env
  depends_on            = [ module.create_gke_1,module.create_gke_2 ]
}

module "acm-1" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//acm/"
  gke_cluster_id        = local.gke_cluster_id_1
  gke_cluster_name      = module.create_gke_1.cluster_name.name
  env                   = var.env
  project_id            = module.create-gcp-project.project.project_id
  git_user              = var.github_user
  git_email             = var.github_email
  git_org               = var.github_org
  github_token          = var.github_token
  acm_repo              = var.acm_repo
}

module "acm-2" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//acm/"
  gke_cluster_id        = local.gke_cluster_id_2
  gke_cluster_name      = module.create_gke_2.cluster_name.name
  env                   = var.env
  project_id            = module.create-gcp-project.project.project_id
  git_user              = var.github_user
  git_email             = var.github_email
  git_org               = var.github_org
  github_token          = var.github_token
  acm_repo              = var.acm_repo
  enable_config_management = 0
  depends_on            = [module.acm-1]
}

module "mci" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//mci/"
  membership_id         = module.acm-1.membership_id
  project_id            = module.create-gcp-project.project.project_id
}

module "artifact-registry-iam-1" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//artifact-registry/render"
  git_user              = var.github_user
  git_email             = var.github_email
  git_org               = var.github_org
  github_token          = var.github_token
  git_repo              = "terraform-modules"
  cluster_name          = module.create_gke_1.cluster_name.name
  service_account_name  = module.create_gke_1.cluster_name.service_account
}

module "artifact-registry-iam-2" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//artifact-registry/render"
  git_user              = var.github_user
  git_email             = var.github_email
  git_org               = var.github_org
  github_token          = var.github_token
  git_repo              = "terraform-modules"
  cluster_name          = module.create_gke_2.cluster_name.name
  service_account_name  = module.create_gke_2.cluster_name.service_account
  depends_on = [ module.artifact-registry-iam-1 ]
}

module "cloud-deploy-target-1" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//cloud-deploy-targets/render"
  git_user              = var.github_user
  git_email             = var.github_email
  git_org               = var.github_org
  github_token          = var.github_token
  git_repo              = "terraform-modules"
  cluster_name          = module.create_gke_1.cluster_name.name
  cluster_path          = local.gke_cluster_id_1
  require_approval      = "false"
  depends_on            = [ module.artifact-registry-iam-1, module.artifact-registry-iam-2]
  env_name              = "prod-1"
}

module "cloud-deploy-target-2" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//cloud-deploy-targets/render"
  git_user              = var.github_user
  git_email             = var.github_email
  git_org               = var.github_org
  github_token          = var.github_token
  git_repo              = "terraform-modules"
  cluster_name          = module.create_gke_2.cluster_name.name
  cluster_path          = local.gke_cluster_id_2
  require_approval      = "false"
  depends_on            = [ module.artifact-registry-iam-1, module.artifact-registry-iam-2,module.cloud-deploy-target-1 ]
  env_name              = "prod-2"
}
module "landing-zone-template" {
  source                = "git::https://github.com/Rote-tech/terraform-modules.git//landing-zone/render"
  git_user              = var.github_user
  git_email             = var.github_email
  git_org               = var.github_org
  tf_modules_repo       = "terraform-modules"
  cluster_name          = module.create_gke_1.cluster_name.name
  cluster_project_id    = module.create-gcp-project.project.project_id
  depends_on            = [ module.artifact-registry-iam-1, module.artifact-registry-iam-2, module.cloud-deploy-target-1, module.cloud-deploy-target-2 ]
  env                   = var.env
  index                 = 2
}