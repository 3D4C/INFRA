# Used to initialize GCP Provider
provider "google" {
  project = var.project_id
  region = var.region
}

# Fetches data from the service account for the current project
data "google_project" "project" {}

# Granting secret manager permissions to the tf service account
resource "google_secret_manager_secret_iam_member" "secret-access" {
  secret_id = var.secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}

# Store secrets for accessing remote registries
module "secret-manager" {
  source  = "GoogleCloudPlatform/secret-manager/google"
  version = "~> 0.8"
  project_id = var.project_id
  secrets = [
    {
      name                     = var.secret_name
      secret_data              = var.password
    },
  ]
}

# Acts as a tunnel to the ghcr container registry where our one source of truth lies
resource "google_artifact_registry_repository" "ghcr-artifact-registry" {
  location      = var.region
  repository_id = "ghcr-custom-remote"
  description   = "remote custom repository with credential"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    description = "custom ghcr remote with credentials"
    disable_upstream_validation = false
    docker_repository {
      custom_repository {
        uri = var.registry
      }
    }
    upstream_credentials {
      username_password_credentials {
        username = var.user
        password_secret_version = module.secret-manager.secret_versions[0]
      }
    }
  }
}

# Granting artifact registry permissions to the tf service account
resource "google_artifact_registry_repository_iam_member" "upstream-access" {
  repository = "ghcr-artifact-registry"
  role      = "roles/artifactregistry.admin"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}

# Serves container for the frontend
resource "google_cloud_run_v2_service" "cloud-run-frontend" {
  name     = "frontend-tf"
  location = var.region
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_ALL"
  template {
    containers {
      name = "frontend"
      ports {
        container_port = 3000
      }
      startup_probe {
        http_get {
          port = 3000
        }
      }
      image = "${var.region}-docker.pkg.dev/${var.project_id}/ghcr-custom-remote/3d4c/3d-4connect/frontend:latest"
    }
  }
}

# Serves container for the backend
resource "google_cloud_run_v2_service" "cloud-run-backend" {
  name     = "backend-tf"
  location = var.region
  deletion_protection = false
  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  template {
    containers {
      name = "backend"
      image = "${var.region}-docker.pkg.dev/${var.project_id}/ghcr-custom-remote/3d4c/3d-4connect/backend:latest"
      ports {
        container_port = 8080
      }
      startup_probe {
        http_get {
          port = 8080
        }
      }
    }
  }
}