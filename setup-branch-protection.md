# Branch Protection Setup Instructions

To set up branch protection for the `main` branch, follow these steps:

## Manual Setup via GitHub Web Interface

1. Go to: https://github.com/robcole/yolo.cr/settings/branches
2. Click "Add rule" or "Add protection rule"
3. Configure the following settings:

### Branch Name Pattern
- `main`

### Protection Rules
- ✅ **Require a pull request before merging**
  - ✅ Require approvals: `1`
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ❌ Require review from code owners (not needed for this project)
  - ❌ Restrict pushes that create files larger than 100MB (default)

- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Required status checks:
    - `docker-lint`
    - `docker-test` 
    - `docker-integration-test`

- ✅ **Require conversation resolution before merging**
- ✅ **Require signed commits** (optional but recommended)
- ✅ **Require linear history** (optional but recommended)
- ✅ **Include administrators** (enforce rules for admins too)
- ❌ **Allow force pushes** (disabled for safety)
- ❌ **Allow deletions** (disabled for safety)

4. Click "Create" to save the protection rule

## Alternative: Using GitHub CLI (if the API format gets fixed)

```bash
gh api repos/robcole/yolo.cr/branches/main/protection -X PUT \
  --input branch-protection.json
```

Where `branch-protection.json` contains the protection rules.

## Verification

After setup, verify protection is active:
```bash
gh api repos/robcole/yolo.cr/branches/main/protection
```

This should return the configured protection settings instead of a 404 error.