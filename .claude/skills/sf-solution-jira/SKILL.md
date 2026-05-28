---
name: sf-solution-jira
description: >
  Jira integration orchestrator for Salesforce solution design. Fetches user story from Jira,
  invokes sf-solution skill to generate technical solution, and posts result back to Jira.
  Use when user wants to design solution for a Jira ticket.
keywords: ["jira", "solution", "user story", "technical design", "atlassian"]
---

# sf-solution-jira: Jira Solution Orchestration

Orchestration layer for Jira-integrated solution design workflow.

## Purpose

Bridge between Jira and sf-solution skill:
1. **Fetch** — Get user story from Jira via Atlassian MCP
2. **Design** — Invoke sf-solution skill to generate technical solution (with interactive wizard)
3. **Persist** — Post solution back to Jira "Technical Solution" field

## When to Use

- User provides Jira issue key (PROJ-123, DEV-456)
- User says "design solution for [Jira ticket]"
- User mentions "create technical solution from Jira story"

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    sf-solution-jira (skill)                 │
│                                                             │
│  1. Fetch Story from Jira (MCP)                            │
│         ↓                                                   │
│  2. Read & follow sf-solution skill ────────────┐          │
│         ↓                                        │          │
│  3. Receive solution (markdown + JSON)          │          │
│         ↓                                        │          │
│  4. Post to Jira "Technical Solution" field     │          │
│                                                  │          │
└──────────────────────────────────────────────────┼──────────┘
                                                   │
                                                   ▼
                                    ┌──────────────────────────┐
                                    │   sf-solution (skill)    │
                                    │   [runs in main context] │
                                    │                          │
                                    │  • Parse requirements    │
                                    │  • Gather context        │
                                    │  • Ask user questions ✨ │
                                    │    (interactive wizard)  │
                                    │  • Generate solution     │
                                    │  • Return markdown+JSON  │
                                    └──────────────────────────┘
```

**Key improvement**: sf-solution runs in the main context, enabling interactive `AskUserQuestion` wizard!

## Instructions

### Step 1: Fetch Jira Story

Use Atlassian MCP to retrieve the issue:

```
mcp__mcp-atlassian__jira_get_issue({
  issue_key: "<JIRA-KEY>",
  fields: "summary,description,issuetype,labels,status,priority,assignee,reporter,created,updated"
})
```

**Parse the response:**
- Extract summary, description, acceptance criteria
- Note issue type, labels, priority
- Capture any custom fields relevant to solution design

### Step 2: Invoke sf-solution skill

Read and follow the sf-solution skill instructions:

1. **Read the skill file**:
   ```
   Read: .claude/skills/sf-solution/SKILL.md
   ```

2. **Follow the skill instructions** with the Jira story as input:

   **Context to provide**:
   ```
   # Jira Story: <JIRA-KEY>

   **Summary:** [story summary]

   **Description:**
   [full story description]

   **Issue Type:** [type]
   **Priority:** [priority]
   **Labels:** [labels]
   **Assignee:** [assignee]
   **Reporter:** [reporter]

   [Include any additional user preferences or context]
   ```

3. **Execute sf-solution workflow**:
   - Phase 1: Parse requirements from Jira story
   - Phase 2: Use interactive Clarification Wizard (AskUserQuestion) ✨
   - Phase 3: Discover context from .claude/ and codebase
   - Phase 4: Design solution with decisions and rationale
   - Phase 5: Self-validate (design-level)
   - Phase 6: Generate outputs (Markdown + JSON)

4. **Capture outputs**:
   - Markdown summary for posting to Jira
   - JSON for potential dev-agent handoff
   - Files to create/edit list

**Important**: The skill runs in the main context, so interactive clarification questions will work!

### Step 3: Post Solution to Jira

Update the Jira issue with the technical solution:

```
mcp__mcp-atlassian__jira_update_issue({
  issue_key: "<JIRA-KEY>",
  fields: {
    "customfield_10082": "[Markdown summary from sf-solution skill]"
  }
})
```

**Custom Field ID**: `customfield_10082` is the "Technical Solution" field in your Jira instance.

### Step 4: Confirm to User

Provide user with:
- Link to updated Jira issue
- Summary of solution posted
- Next steps (e.g., "Review solution in Jira, then use dev-agent to implement")

## Error Handling

| Error | Action |
|-------|--------|
| Invalid Jira key format | Prompt for correct format (PROJ-123) |
| Issue not found | Verify key, check Jira access permissions |
| Jira MCP unavailable | Fall back to asking user to paste story text, then invoke sf-solution skill directly |
| sf-solution skill fails | Surface error to user, offer to retry or proceed without Jira update |
| Update Jira fails (field not found) | Verify customfield_10082 exists in Jira, show solution to user, offer manual update |
| Update Jira fails (other) | Show solution to user, explain Jira update failed, offer to retry |

## Examples

### Example 1: Simple usage

User: "Design solution for PROJ-123"

→ Fetch PROJ-123 from Jira
→ Read and follow sf-solution skill
→ Interactive wizard asks clarifying questions ✨
→ Post solution back to PROJ-123

### Example 2: With preferences

User: "Create solution for DEV-456, prefer LWC over Aura"

→ Fetch DEV-456
→ Read sf-solution skill, include note: "User prefers LWC over Aura"
→ Interactive wizard may ask follow-up questions
→ Post solution back

### Example 3: Jira unavailable

User: "Design for PROJ-789"

→ Attempt to fetch, fails
→ Ask user to paste story
→ Read and follow sf-solution skill with pasted text
→ Show solution to user (skip Jira update)

## Integration Points

### Atlassian MCP Tools Used

- `mcp__mcp-atlassian__jira_get_issue` — Fetch story
- `mcp__mcp-atlassian__jira_search_fields` — Find custom field ID
- `mcp__mcp-atlassian__jira_update_issue` — Post solution back

### Skills Used

- `sf-solution` — Generate technical solution (interactive)

### Output Format

Present to user:

```markdown
✅ Solution created for [JIRA-KEY]

## Summary
[1-2 sentence summary from sf-solution skill]

## Key Decisions
- [Decision 1]
- [Decision 2]

## Components
[List of objects/classes/LWCs]

🔗 View in Jira: [link to issue]

📋 Solution posted to "Technical Solution" field

## Next Steps
1. Review the solution in Jira
2. If approved, use dev-agent to implement
3. Or refine requirements and regenerate solution
```

## Tips

1. **Always fetch from Jira first** — Don't assume story content
2. **Pass full context to sf-solution** — Include all Jira fields, not just description
3. **Handle user preferences** — If user says "use X pattern", include in context for sf-solution
4. **Let the wizard work** — sf-solution uses interactive AskUserQuestion, so user can clarify on the fly
5. **Confirm Jira update** — Show user the update succeeded and provide link
6. **Graceful degradation** — If Jira unavailable, still generate solution without posting back
