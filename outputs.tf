output "service_url" {
  value = google_cloud_run_v2_service.app.uri
}

output "trigger_id" {
  value = google_cloudbuild_trigger.main.id
}

output "artifact_registry_repo" {
  value = google_artifact_registry_repository.labs.name
}
