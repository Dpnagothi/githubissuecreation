#!/usr/bin/env python3
"""Validate parsed issue-form JSON and write a Terraform tfvars file.

Issue bodies are untrusted input. Every field is checked against a strict
pattern and only reaches Terraform as JSON data, never inside a shell command.

Input : env FORM_JSON (from stefanbuck/github-issue-parser), ISSUE_NUMBER
Output: terraform/request.auto.tfvars.json, `name` on $GITHUB_OUTPUT,
        validation_errors.md on failure
"""
import json
import os
import re
import sys

errors = []
form = json.loads(os.environ["FORM_JSON"])
issue_number = int(os.environ["ISSUE_NUMBER"])


def field(key):
    value = form.get(key)
    if isinstance(value, str):
        value = value.strip()
        if value in ("", "_No response_", "None"):
            return None
    return value


repo_name = field("repo_name") or ""
if not re.fullmatch(r"[a-z][a-z0-9-]{2,59}", repo_name):
    errors.append("`Repository name` must be 3-60 chars: lowercase letters, digits, hyphens, starting with a letter.")

description = field("description") or ""
if not (1 <= len(description) <= 200) or re.search(r"[\x00-\x1f]", description):
    errors.append("`Description` must be 1-200 characters on a single line.")

visibility = field("visibility") or ""
if visibility not in {"private", "internal", "public"}:
    errors.append("`Visibility` must be private, internal or public.")

team_slug = field("team_slug")
if team_slug is not None and not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,99}", team_slug):
    errors.append("`Owning team` must be a team slug (lowercase letters, digits, hyphens).")

team_permission = field("team_permission") or ""
if team_permission not in {"pull", "push", "maintain", "admin"}:
    errors.append("`Team permission` must be pull, push, maintain or admin.")

required_reviews = field("required_reviews") or ""
if required_reviews not in {"0", "1", "2"}:
    errors.append("`Required PR approvals` must be 0, 1 or 2.")

options = field("options") or []

if errors:
    with open("validation_errors.md", "w") as f:
        f.write("\n".join(f"- {e}" for e in errors))
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)

tfvars = {
    "repo_name": repo_name,
    "description": description,
    "visibility": visibility,
    "team_slug": team_slug,
    "team_permission": team_permission,
    "required_reviews": int(required_reviews),
    "protect_main": "Protect the main branch" in options,
    "has_issues": "Enable issues" in options,
    "standard_labels": "Add standard labels" in options,
    "request_issue": issue_number,
}

with open("terraform/request.auto.tfvars.json", "w") as f:
    json.dump(tfvars, f, indent=2)

with open(os.environ["GITHUB_OUTPUT"], "a") as out:
    out.write(f"name={repo_name}\n")

print(json.dumps(tfvars, indent=2))
