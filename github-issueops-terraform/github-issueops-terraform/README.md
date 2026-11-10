# IssueOps: GitHub Issue Form → Approval → Terraform (GitHub only)

No cloud account needed. A user fills a **GitHub Issue Form**, a workflow posts a
**Terraform plan** on the issue, an approver comments **`/approve`**, and Terraform
applies. The issue *is* the audit trail: who asked, what plan, who approved, what changed.
State is stored in this same repo on a `terraform-state` branch.

The example Terraform uses the **GitHub provider** to create a repository (with
branch protection, team access and labels). Swap `terraform/` for anything else.

```
.github/
  ISSUE_TEMPLATE/repo-request.yml        # the form
  ISSUE_TEMPLATE/config.yml              # disables blank issues
  actions/tf-prepare/action.yml          # parse + validate + state checkout + init (shared)
  workflows/issueops-terraform.yml       # plan / approve / reject
scripts/form_to_tfvars.py                # validates untrusted form input → tfvars JSON
terraform/                               # GitHub-provider config
```

## Setup (one time)

1. **Push** these files to `main` of a repo in your org (e.g. `platform-requests`).
2. **State branch** (empty, orphan):
   ```bash
   git switch --orphan terraform-state
   git commit --allow-empty -m "init terraform state"
   git push origin terraform-state
   git switch main
   ```
   Keep the repo **private**: state files can contain sensitive values.
3. **Token for Terraform**: `GITHUB_TOKEN` can't create repos or manage teams, so add a
   secret **`TF_GITHUB_TOKEN`**: a fine-grained PAT, or better a GitHub App installation token,
   with org *Administration: write* + *Members: read* (only what your Terraform manages).
4. **Approvers**: repo variable **`APPROVERS`** = `alice,bob,carol` (GitHub usernames).
5. **Labels**: `tf-request`, `awaiting-approval`, `needs-fix`, `provisioned`, `rejected`.
6. **Protect** `main` and `terraform-state`, and add CODEOWNERS for `/.github/` and `/terraform/`
   so the pipeline and Terraform can't change without platform review.
   (Allow GitHub Actions to push to `terraform-state`.)

## Flow

| Who | Action | What happens |
|---|---|---|
| Requester | New issue → *Repository Request* | `plan` job: validate → `terraform plan` → plan comment (with hidden plan fingerprint) → `awaiting-approval` |
| Requester | Edits issue | New plan comment; older plans become invalid |
| Anyone | `/plan` | Re-plan |
| Approver | `/approve` | Checks approver ∈ `APPROVERS` and ≠ author → issue unchanged since plan → re-plan and **verify identical** to the reviewed plan → apply → commit state → comment outputs → close |
| Approver | `/reject` | Close as *not planned* |

## Safety

- Form text is untrusted: passed via `env:`, validated in Python, given to Terraform only as JSON.
- Workflows triggered by issues/comments run from `main`, not from anything the requester controls.
- Comments posted by the workflow's own `GITHUB_TOKEN` don't trigger new runs (no loops).
- `/approve` applies only if the fresh plan's SHA-256 equals the one the approver saw.
- Applies are serialized (`concurrency: tf-apply`), so the shared state branch never races.
