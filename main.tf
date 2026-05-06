terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_artifact_registry_repository" "labs" {
  location      = var.region
  repository_id = "labs"
  format        = "DOCKER"
}

resource "google_cloud_run_v2_service" "app" {
  name     = "ship-it"
  location = var.region

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image
    ]
  }
}

data "google_project" "project" {}

resource "google_project_iam_member" "cloudbuild_run_admin" {
  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_artifact_writer" {
  project = var.project
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_cloudbuild_trigger" "main" {
  name = "ship-it-on-push"

  github {
    owner = var.gh_owner
    name  = var.gh_repo

    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  depends_on = [
    google_artifact_registry_repository.labs,
    google_cloud_run_v2_service.app,
    google_project_iam_member.cloudbuild_run_admin,
    google_project_iam_member.cloudbuild_artifact_writer,
    google_project_iam_member.cloudbuild_service_account_user
  ]
}
