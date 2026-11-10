output "repository_url" {
  value = github_repository.this.html_url
}

output "clone_url" {
  value = github_repository.this.ssh_clone_url
}

output "main_protected" {
  value = var.protect_main
}

output "team_access" {
  value = var.team_slug == null ? "none" : "${var.team_slug} (${var.team_permission})"
}
