terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # State is kept in this same repo, on the `terraform-state` branch.
  # The workflow passes the file path with -backend-config="path=...",
  # one state file per request (state/<repo-name>.tfstate).
  backend "local" {}
}

# Authenticates with the GITHUB_TOKEN environment variable, which the workflow
# sets from the TF_GITHUB_TOKEN secret (PAT or GitHub App token).
provider "github" {
  owner = var.github_owner
}
