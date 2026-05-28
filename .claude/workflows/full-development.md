# Full Development Workflow

Jira Story to Pull Request - Complete development workflow using sf-solution skill + 4 agents.

## Workflow Diagram

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                          MAIN CONTEXT (CLAUDE.md)                              │
│                                                                                │
│  ┌──────────────────────────────────────────────────────┐                     │
│  │  sf-solution skill (runs in main context)            │                     │
│  │  • ANALYZE • CLARIFY (wizard) • DESIGN • VALIDATE    │                     │
│  └────────────────────────────┬─────────────────────────┘                     │
│                               │                                               │
│                            HITL ──┐                                           │
└───────────────────────────────────┼───────────────────────────────────────────┘
                                    │
                                    ▼
                       ┌──────────────────┐
                       │    dev-agent     │
                       │    (sonnet)      │
                       ├──────────────────┤
                       │ • CODE           │
                       │ • TEST           │
                       │ • REVIEW         │
                       │ • ITERATE        │
                       └────────┬─────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   deploy-agent   │
                       │    (haiku)       │
                       ├──────────────────┤
                       │ • DEPLOY         │
                       │ • FIX ERRORS     │
                       │ • VERIFY         │
                       └────────┬─────────┘
                                │
                                ▼
                  ┌───────────────────────────┐
                  │   browser-verify-agent    │
                  │        (sonnet)           │
                  ├───────────────────────────┤
                  │ • NAVIGATE & INSPECT      │
                  │ • CONSOLE ERRORS          │
                  │ • SCREENSHOTS             │
                  └────────────┬──────────────┘
                               │
                               ▼
                       ┌──────────────────┐
                       │     pr-agent     │
                       │     (sonnet)     │
                       ├──────────────────┤
                       │ • Branch         │
                       │ • Commit         │
                       │ • PR             │
                       └──────────────────┘
```

## Philosophy: Skill + 4 Agents

**Agent = zone of responsibility with isolated context**. But solution design needs interactivity → use skill in main context.

| Old Structure | Problem | New Structure |
|---------------|---------|---------------|
| solution-generator + solution-validator | Validator loses "why" context | **sf-solution skill** (runs in main, enables wizard) |
| apex-coder + apex-reviewer + test-coder | Reviewer can't see decision context | **dev-agent** (all in one) |
| sf-project-deploy | Already isolated ✓ | **deploy-agent** |
| manual browser QA | No structured verification | **browser-verify-agent** |
| pr-builder | Already isolated ✓ | **pr-agent** |

## Stages

### 1. sf-solution skill

**Purpose**: Analyze requirements → Interactive clarification → Design solution → Self-validate

**Runs in**: Main context (not subagent) — enables interactive `AskUserQuestion` wizard

**Input**:
- Jira story URL or content
- Project context from `.claude/context/`

**Process**:
1. Parse requirements (entities, actions, rules)
2. **Interactive Clarification Wizard** — ask user questions to resolve ambiguities
3. Discover project context (existing patterns)
4. Design solution (objects, apex, lwc, permissions)
5. Self-validate (limits, best practices, duplicates)
6. Output structured solution

**Output**:
- Solution markdown (for human review) — concise, DRY format
- Solution JSON (for dev-agent)

**HITL Checkpoint**: Review solution before implementation

---

### 2. dev-agent

**Purpose**: Write code + tests + self-review (one continuous context)

**Model**: `sonnet` (coding requires reasoning)

**Input**:
- Solution JSON from sf-solution skill
- Project context (technology patterns)

**Process**:
1. Load relevant skills (sf-apex, sf-lwc, sf-testing, etc.)
2. Implement components in dependency order
3. Self-review against skill criteria
4. Write tests (PNB: Positive, Negative, Bulk)
5. Run tests locally
6. Fix failures (iterate max 3x)

**Output**:
- Created files list
- Modified files list
- Test results + coverage

**Why one agent?**
- Agent writes code → knows why it made decisions
- Agent reviews own code → can self-critique with full context
- Agent writes tests → knows implementation details
- Agent fixes failures → has full context to debug

---

### 3. deploy-agent

**Purpose**: Deploy to org + handle errors + verify

**Model**: `haiku` (procedural work, no deep reasoning)

**Input**:
- Files to deploy from dev-agent
- Target org (from sfdx-project.json)

**Process**:
1. Validate files exist
2. Deploy: `sf project deploy start`
3. Handle errors (fix fixable issues)
4. Retry (max 3 attempts)
5. Verify deployment

**Output**:
- Deployment status
- Errors (if failed)
- Fixes applied (if any)

**What it can fix**: API version, missing meta.xml, XML syntax
**What it escalates**: Logic errors, test failures

---

### 4. browser-verify-agent

**Purpose**: Verify deployed implementation in the browser using Chrome DevTools MCP

**Model**: `sonnet` (needs reasoning to derive verification steps from context)

**Input**:
- Implementation context from dev-agent (what was built)
- Org URL (base Salesforce URL)

**Process**:
1. Derive verification plan from implementation context
2. Resolve target page URLs
3. Navigate to pages, take snapshots, check console
4. Verify component rendering and interactions
5. Capture screenshots as evidence
6. Compile verification report

**Output**:
- Verification status (pass/partial/fail)
- Screenshots for each check
- Console errors summary
- Recommendations if issues found

**When to run**: After successful deployment, especially when UI components (LWC, page layouts, flows) are part of the implementation.

**When to skip**: Backend-only changes (Apex triggers, batch jobs, scheduled classes) with no UI impact.

---

### 5. pr-agent

**Purpose**: Create branch + commit + push + PR

**Model**: `sonnet` (documentation benefits from quality)

**Input**:
- Solution summary
- Files changed
- Test results
- Jira reference

**Process**:
1. Analyze git diff (fresh perspective on changes)
2. Generate PR description
3. Create branch (if needed)
4. Commit with conventional format
5. Push to remote
6. Create PR via `gh`

**Output**:
- PR URL

**HITL Checkpoint**: Review PR before merge

---

## HITL Checkpoints

| Checkpoint | After | Purpose |
|------------|-------|---------|
| Solution Review | sf-solution skill | Verify approach before coding |
| PR Review | pr-agent | Final review before merge |

**Note**: No checkpoint after dev-agent. If tests pass and code is self-reviewed, proceed to deployment. Deployment failures will surface issues.

---

## Error Handling

### In dev-agent (test failures)
```
test fails → analyze error → fix code/test → re-run (max 3x)
           → still fails → report to orchestrator
```

### In deploy-agent (deployment errors)
```
deploy fails → analyze error → fix if possible → retry (max 3x)
             → can't fix (logic error) → report to orchestrator → escalate to dev-agent
```

### In browser-verify-agent (verification failures)
```
check fails → capture evidence (screenshot + console) → report findings
            → transient failure (timeout, stale page) → retry (max 3x)
```

---

## Modes

### Standard Mode (with HITL)
Pauses at checkpoints for human approval.

```
sf-solution skill → HITL → dev-agent → deploy-agent → browser-verify-agent → pr-agent → HITL
```

### Auto Mode
Runs end-to-end without pauses. Use for trusted, simple tasks.

```
sf-solution skill → dev-agent → deploy-agent → browser-verify-agent (if UI changes) → pr-agent
```

---

## Invocation

Standard mode:
```
Implement this Jira story: [JIRA-123]
```

Auto mode:
```
Implement this Jira story: [JIRA-123], auto mode
```

Direct invocation:
```
Design solution for: [requirements]  (uses sf-solution skill)
Run dev-agent with solution: [solution JSON]
Run deploy-agent for files: [file list]
Run browser-verify-agent for: [implementation description]
Run pr-agent with Jira: [JIRA-123]
```
