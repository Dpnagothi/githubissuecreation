variable "github_owner" {
  description = "Organization (or user) the repositories are created in. Set by the workflow."
  type        = string
}

variable "repo_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,59}$", var.repo_name))
    error_message = "repo_name must be 3-60 lowercase chars."
  }
}

variable "description" {
  type = string
}

variable "visibility" {
  type = string
  validation {
    condition     = contains(["private", "internal", "public"], var.visibility)
    error_message = "visibility must be private, internal or public."
  }
}

variable "team_slug" {
  type    = string
  default = null
}

variable "team_permission" {
  type    = string
  default = "push"
}

variable "required_reviews" {
  type    = number
  default = 1
}

variable "protect_main" {
  type    = bool
  default = true
}

variable "has_issues" {
  type    = bool
  default = true
}

variable "standard_labels" {
  type    = bool
  default = true
}

variable "request_issue" {
  description = "Issue number that requested this repo (traceability)."
  type        = number
}
