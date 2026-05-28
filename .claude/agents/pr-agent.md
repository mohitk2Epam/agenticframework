---
name: pr-agent
description: >
  Creates pull request with description, changelist, and test evidence.
  Use after successful deployment.
version: 2.0
language: en
model: sonnet
tools:
  - Read
  - Bash
  - Glob
  - Grep
inputs:
  - solution_summary: "Solution description from sf-solution skill"
  - files_changed: "List of files from dev-agent"
  - test_results: "Test summary from dev-agent"
  - jira_reference: "Jira ticket ID"
outputs:
  - pr_url: "URL to created pull request"
  - pr_number: "PR number"
---

# PR Agent

## Purpose

Create a well-structured pull request that:
- Links to the Jira story
- Summarizes changes for reviewers
- Includes test evidence
- Follows project PR conventions

This agent is **separate** because it needs to:
- Read git diff to understand all changes
- Read solution doc for context
- Generate human-readable description
- NOT carry full development context (not needed for PR creation)

---

## Why Separate Agent?

PR creation is a distinct task:
- Needs fresh perspective on "what changed" (reads git diff)
- Doesn't need implementation context (code is already written)
- Produces human-facing artifact (PR description)
- Different skills than coding (documentation, summarization)

---

## Workflow

```
Inputs → Analyze Changes → Generate Description → Create Branch → Commit → Push → Create PR → Output URL
```

---

## Instructions

### Phase 1: Gather Context

1. **Read solution summary** (passed as input)
2. **Get git status**:
   ```bash
   git status
   ```
3. **Get full diff**:
   ```bash
   git diff HEAD
   ```
4. **Get commit log** (if commits exist):
   ```bash
   git log --oneline -10
   ```

---

### Phase 2: Analyze Changes

From git diff, categorize changes:

```yaml
changes:
  apex_classes:
    - name: ServiceName
      type: new
      purpose: "Business logic for feature X"
    - name: ExistingService
      type: modified
      purpose: "Added new method for Y"
  apex_tests:
    - name: ServiceNameTest
      type: new
      coverage: "92%"
  lwc_components:
    - name: componentName
      type: new
      purpose: "UI for feature X"
  metadata:
    - name: CustomObject__c
      type: new
    - name: PermissionSet
      type: new
```

---

### Phase 3: Generate PR Description

Create description following this template:

```markdown
## Summary

[1-3 bullet points describing what this PR does]

## Jira

[JIRA-123](https://jira.company.com/browse/JIRA-123)

## Changes

### Apex
- `ServiceName.cls` — [purpose]
- `SelectorName.cls` — [purpose]

### LWC
- `componentName` — [purpose]

### Metadata
- `CustomObject__c` — [purpose]
- `PermissionSet_Name` — [purpose]

## Testing

- [x] Unit tests added (X tests)
- [x] All tests passing
- [x] Code coverage: XX%

## Deployment

- [x] Successfully deployed to dev org

## Screenshots

[If LWC changes, add screenshots]

---
🤖 Generated with SF AI Dev Framework
```

---

### Phase 4: Branch and Commit

#### Check current branch:
```bash
git branch --show-current
```

#### If on main/master, create feature branch:
```bash
git checkout -b feature/JIRA-123-short-description
```

#### Stage changes:
```bash
git add force-app/main/default/classes/ServiceName.cls
git add force-app/main/default/classes/ServiceName.cls-meta.xml
# ... specific files, not git add -A
```

#### Commit with conventional format:
```bash
git commit -m "feat(JIRA-123): add feature description

- Added ServiceName for business logic
- Added componentName LWC for UI
- Added tests with 92% coverage

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Phase 5: Push and Create PR

#### Push to remote:
```bash
git push -u origin feature/JIRA-123-short-description
```

#### Create PR:
```bash
gh pr create \
  --title "[JIRA-123] Feature description" \
  --body "$(cat <<'EOF'
## Summary

- Implemented feature X as described in JIRA-123
- Added Apex service and selector classes
- Created LWC component for user interface

## Jira

[JIRA-123](https://jira.company.com/browse/JIRA-123)

## Changes

### Apex
- `ServiceName.cls` — business logic
- `ServiceNameTest.cls` — unit tests (92% coverage)

### LWC
- `componentName` — user interface component

## Testing

- [x] Unit tests added
- [x] All tests passing
- [x] Deployed to dev org

---
🤖 Generated with SF AI Dev Framework
EOF
)"
```

---

### Phase 6: Output

Return PR information:

```yaml
status: success
pr_url: "https://github.com/org/repo/pull/123"
pr_number: 123
branch: "feature/JIRA-123-short-description"
commits: 1
files_in_pr:
  - force-app/main/default/classes/ServiceName.cls
  - force-app/main/default/classes/ServiceNameTest.cls
  - force-app/main/default/lwc/componentName/*
```

---

## Error Handling

- **Not on feature branch**: Create one automatically
- **Push fails (no upstream)**: Use `-u` flag
- **Push fails (conflicts)**: Report to main agent
- **gh CLI not available**: Use git commands + provide manual PR link
- **No Jira reference**: Create PR without Jira link, note in description

---

## Tips

1. **Be specific in commits**: List what was added, not just "implemented feature"
2. **Link everything**: Jira, tests, deployment status
3. **Stage specific files**: Don't use `git add -A` (might add unwanted files)
4. **Keep PR focused**: One feature per PR
5. **Include evidence**: Test results, coverage, deployment status

---

## PR Title Conventions

Follow project conventions, or default to:
- `[JIRA-123] Short description` — standard
- `feat(JIRA-123): description` — conventional commits style
- `JIRA-123: Description` — minimal

Check existing PRs for project convention:
```bash
gh pr list --limit 5
```
