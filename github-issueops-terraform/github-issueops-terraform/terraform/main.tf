resource "github_repository" "this" {
  name        = var.repo_name
  description = "${var.description} (requested in issue #${var.request_issue})"
  visibility  = var.visibility

  has_issues   = var.has_issues
  has_projects = false
  has_wiki     = false
  auto_init    = true # creates main so branch protection can attach

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  delete_branch_on_merge = true

  vulnerability_alerts = true
}

resource "github_branch_protection" "main" {
  count         = var.protect_main ? 1 : 0
  repository_id = github_repository.this.node_id
  pattern       = "main"

  enforce_admins          = false
  required_linear_history = true

  required_pull_request_reviews {
    required_approving_review_count = var.required_reviews
    dismiss_stale_reviews           = true
  }
}

data "github_team" "owner" {
  count = var.team_slug == null ? 0 : 1
  slug  = var.team_slug
}

resource "github_team_repository" "owner" {
  count      = var.team_slug == null ? 0 : 1
  team_id    = data.github_team.owner[0].id
  repository = github_repository.this.name
  permission = var.team_permission
}

locals {
  labels = {
    "bug"          = { color = "d73a4a", description = "Something isn't working" }
    "enhancement"  = { color = "a2eeef", description = "New feature or request" }
    "incident"     = { color = "b60205", description = "Production incident" }
    "tech-debt"    = { color = "fbca04", description = "Cleanup / refactor" }
    "dependencies" = { color = "0366d6", description = "Dependency updates" }
  }
}

resource "github_issue_labels" "standard" {
  count      = var.standard_labels ? 1 : 0
  repository = github_repository.this.name

  dynamic "label" {
    for_each = local.labels
    content {
      name        = label.key
      color       = label.value.color
      description = label.value.description
    }
  }
}
