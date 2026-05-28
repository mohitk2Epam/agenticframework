# SF AI Dev Framework

AI-assisted Salesforce development: Jira story to pull request in one session.

## How It Works

```
sf-solution skill          dev-agent          deploy-agent      browser-verify-agent     pr-agent
(main context)             (sonnet)           (haiku)           (sonnet)                 (sonnet)

  ANALYZE                    CODE               DEPLOY            NAVIGATE                 BRANCH
  CLARIFY (wizard)           TEST               FIX ERRORS        INSPECT DOM              COMMIT
  DESIGN                     REVIEW             VERIFY            CONSOLE ERRORS           PR
  VALIDATE                   ITERATE                              SCREENSHOTS
       │                       │                   │                   │                     │
       ▼                       ▼                   ▼                   ▼                     ▼
  Solution JSON ──────▶ Implementation ────▶ Deployed org ────▶ Verification ────▶ Pull request
       │                                                        evidence
    HITL checkpoint                                                                  HITL checkpoint
```

**Skills** = domain knowledge (patterns, templates, scoring rubrics). Loaded on-demand by agents.
**Agents** = context-isolated workflow executors. Each owns a zone of responsibility.
**sf-solution** = the only interactive skill. Runs in main context to enable clarification wizard via `AskUserQuestion`.

## Architecture

```
.claude/
├── CLAUDE.md                  # Entry point (auto-loaded by Claude Code)
├── skills-registry.json       # Skill + agent discovery
├── skills/
│   ├── sf-solution/           # Interactive: requirements → technical design
│   ├── sf-solution-jira/      # Orchestration: Jira fetch → sf-solution → post back
│   ├── sf-apex/               # Apex patterns, generation, 150-point scoring
│   ├── sf-lwc/                # LWC: PICKLES architecture, wire, events, Jest
│   ├── sf-testing/            # PNB pattern, factories, coverage, test-fix loops
│   ├── sf-soql/               # Query generation, optimization, security
│   ├── sf-deploy/             # Deployment commands, error patterns, retry
│   ├── sf-metadata/           # Objects, fields, permission sets, validation rules
│   ├── sf-permissions/        # Permission set analysis, FLS, "who has X?" audit
│   ├── sf-data/               # Test data factories, bulk operations
│   ├── sf-debug/              # Debug log parsing, governor limits, stack traces
│   └── shared/                # Code analyzer, hooks, LSP engine, SOQL extractor
├── agents/
│   ├── dev-agent.md           # Code + Test + Review (one context)
│   ├── deploy-agent.md        # Deploy + Fix + Verify
│   ├── browser-verify-agent.md # Browser verification via Chrome DevTools MCP
│   └── pr-agent.md            # Branch + Commit + PR
├── context/                   # Project knowledge (populated by AIInitFramework)
└── workflows/
    └── full-development.md    # Full Jira → PR workflow definition
```

## Agents

| Agent | Model | What It Does | Skills Loaded |
|-------|-------|-------------|---------------|
| `dev-agent` | sonnet | Writes Apex, LWC, metadata, tests. Self-reviews. Deploys and iterates on failures (max 3x). | sf-apex, sf-lwc, sf-testing, sf-soql, sf-metadata, sf-deploy |
| `deploy-agent` | haiku | Deploys to org. Parses errors, applies fixes (API version, meta.xml, XML syntax), retries. Escalates logic errors. | sf-deploy |
| `browser-verify-agent` | sonnet | Navigates live org via Chrome DevTools MCP. Checks rendering, console errors, interactions. Produces screenshots as evidence. | (none — uses Chrome DevTools MCP) |
| `pr-agent` | sonnet | Reads git diff, generates PR description, creates branch, commits, pushes, opens PR via `gh`. | (none — uses git/gh) |

**Why these boundaries?** Agent = zone of responsibility. `dev-agent` keeps code+test+review in one context so it can self-critique with full decision history. `deploy-agent` uses haiku because error handling is procedural. `browser-verify-agent` isolates DOM/console context from code context. `pr-agent` reads diff fresh — no implementation context needed.

## Design Principle

Don't split agents by task granularity. Split by **context isolation need**.

```
Wrong:  apex-coder → apex-reviewer → test-writer  (reviewer loses decision context)
Right:  dev-agent (codes + reviews + tests + fixes in one context)
```

Skills carry knowledge. Agents carry workflow. Skills don't make decisions — agents load skills and use them.

## Setup

### Prerequisites

- `sf` (Salesforce CLI)
- Claude Code or Cursor
- `gh` CLI (for PR creation)
- Atlassian MCP (optional, for Jira integration)
- Chrome DevTools MCP (optional, for browser verification)

### Install

```bash
git clone <repo-url> sf-ai-dev-framework
cd sf-ai-dev-framework
./install.sh /path/to/your/sfdx-project
```

Windows PowerShell 7 users:

```powershell
.\\install.ps1 'D:\path\to\your\sfdx-project'
```

Or copy manually:
```bash
cp -r sf-ai-dev-framework/.claude /path/to/your/sfdx-project/
```

### Generate Project Context

Run [AIInitFramework](https://gitbud.epam.com/Artsiom_Sushchenia/salesforceaiinitframework.git) to populate `.claude/context/` with project-specific knowledge (object model, automations, integrations, security):

```bash
ai-init-framework analyze /path/to/your/sfdx-project
```

## Usage

### Full Workflow (Jira to PR)

```
Design solution for PROJ-123
```

This triggers: Jira fetch → sf-solution wizard → dev-agent → deploy-agent → browser-verify-agent → pr-agent.

Two HITL checkpoints: after solution design (approve before coding) and after PR creation (review before merge).

### Direct Text Input

```
Implement this user story: [paste story text]
```

### Individual Skills

```
Use sf-apex skill to create a service class for Account processing
Use sf-testing skill to write tests for OpportunityService
Use sf-soql skill to optimize this query: [paste query]
```

### Individual Agents

```
Run dev-agent with solution: [solution JSON]
Run deploy-agent for files: [file list]
Run browser-verify-agent for: [what to verify]
Run pr-agent with Jira: PROJ-123
```

### Modes

**Standard** — pauses at HITL checkpoints:
```
sf-solution → HITL → dev-agent → deploy-agent → browser-verify-agent → pr-agent → HITL
```

**Auto** — runs end-to-end (for trusted, simple tasks):
```
Implement this Jira story: PROJ-123, auto mode
```

## Tool Compatibility

| Tool | Setup |
|------|-------|
| Claude Code | Reads `.claude/CLAUDE.md` automatically |
| Cursor | Copy `.claude/CLAUDE.md` to `.cursorrules` |
| Other | Point to `.claude/` directory |
