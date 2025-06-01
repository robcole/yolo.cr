# Conventions

## Types
- Only allow types to be nullable when *absolutely* required.

# Development Workflow

## Pull Request Requirements
Starting immediately, ALL changes to project code must be made through pull requests. Direct pushes to the `main` branch are prohibited.

### Creating Pull Requests
1. **Create a feature branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make your changes** on the feature branch
3. **Test your changes** using Docker workflows:
   ```bash
   cd game_tests
   make docker-all  # Run build, test, and lint
   ```

4. **Commit your changes** with descriptive messages
5. **Push the branch** to GitHub:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a pull request** using GitHub CLI or web interface:
   ```bash
   gh pr create --title "Feature: Your feature description" --body "Detailed description of changes"
   ```

### Pull Request Requirements
- ✅ **All CI checks must pass** (docker-lint, docker-test, docker-integration-test)
- ✅ **At least 1 approving review** required
- ✅ **Branch must be up-to-date** with main before merging
- ✅ **All conversations must be resolved**
- ❌ **No force pushes** to main branch
- ❌ **No direct commits** to main branch

### Branch Protection
The `main` branch is protected with the following rules:
- Require pull request reviews before merging
- Require status checks to pass before merging
- Require conversation resolution before merging
- Include administrators (rules apply to all users)
- Prohibit force pushes and deletions

### Emergency Procedures
In case of critical production issues requiring immediate fixes:
1. Create a hotfix branch: `git checkout -b hotfix/critical-issue`
2. Make minimal necessary changes
3. Create PR with "HOTFIX" prefix and detailed justification
4. Request expedited review
5. Merge after CI passes and approval received

## Branch Naming Conventions
- **Features**: `feature/description` or `feat/description`
- **Bug fixes**: `fix/description` or `bugfix/description`
- **Hotfixes**: `hotfix/description`
- **Documentation**: `docs/description`
- **Refactoring**: `refactor/description`
- **Tests**: `test/description`

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## CRITICAL: Pull Request Workflow Required
ALL code changes MUST be made through pull requests. Direct pushes to main branch are PROHIBITED.
1. Create feature branch: `git checkout -b feature/description`
2. Make changes and test with: `cd game_tests && make docker-all`
3. Push branch: `git push origin feature/description`
4. Create PR: `gh pr create --title "Feature: description" --body "Details"`
5. Wait for CI checks and approval before merging

Branch protection rules are enforced - direct commits to main will be rejected.