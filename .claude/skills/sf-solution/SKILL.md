---
name: sf-solution
description: >
  Generates and validates technical solutions from business requirements.
  Combines analysis, design, and self-validation with interactive clarification wizard.
  Use when user provides a user story, Jira ticket, or business requirement
  that needs a technical approach for Salesforce implementation.
keywords: ["solution", "design", "requirements", "technical design", "architecture"]
version: 2.0
---

# sf-solution: Technical Solution Design

**Interactive solution design skill with clarification wizard.**

## Purpose

Transform business requirements into a validated technical solution. This skill combines:
- **Analysis** — parsing requirements into entities, actions, rules
- **Interactive Clarification** — wizard-style questions to resolve ambiguities
- **Design** — creating technical solution with objects, Apex, LWC, metadata
- **Self-Validation** — challenging own solution for design-level issues

## When to Use

- User provides a user story or requirements document
- User asks to "design solution for [requirement]"
- Called by `sf-solution-jira` skill after fetching Jira story
- Need to generate technical architecture from business needs

## Workflow

```
Requirements → Parse → Clarify (interactive) → Discover Context → Design → Validate → Output
                          ↓
                   [AskUserQuestion]
                   (wizard with 1-4 questions at a time)
```

---

## Instructions

### Phase 1: Parse Requirements

**Goal**: Extract structure from user story and ensure clarity.

1. **Read the requirements** (provided as input text or Jira story)

2. **Identify**:
   - **Entities**: Nouns (Account, Invoice, Payment)
   - **Actions**: Verbs (create, update, calculate, notify)
   - **Rules**: Business logic (if X then Y)
   - **CRUD operations**: What data operations needed
   - **Relationships**: How entities connect
   - **Automation needs**: Triggers, flows, scheduled jobs, LWC

3. **Extract acceptance criteria** if provided

4. **Identify Ambiguities** — Look for:
   - Vague terms (what does "process" mean here?)
   - Missing details (when should this trigger?)
   - Conflicting rules (rule A says X, rule B says Y)
   - Unstated assumptions (bulk vs single record?)
   - Scope boundaries (only this object or related?)
   - Integration points (external systems?)
   - Security requirements (who can access what?)
   - Performance considerations (volume, frequency)

---

### Phase 2: Clarification Wizard (Interactive)

**Goal**: Resolve all ambiguities before designing.

**IMPORTANT**: Use `AskUserQuestion` tool to interactively clarify requirements.

#### When to Ask Questions

Ask if ANY of these conditions exist:
- Ambiguous terminology
- Missing acceptance criteria
- Unclear data volume/frequency
- Unstated security requirements
- Integration details not specified
- Conflicting or contradictory requirements

#### How to Structure Questions

1. **Group related questions** (max 4 questions per call)
2. **Provide options when possible** (easier for user to choose)
3. **Include clear context** in question text
4. **Use descriptive headers** (12 chars max)

#### Example Question Format

```
AskUserQuestion({
  questions: [
    {
      question: "Should this automation run for bulk updates (200+ records)?",
      header: "Bulk Support",
      options: [
        {
          label: "Yes, must handle bulk",
          description: "Design for bulkification (200+ records)"
        },
        {
          label: "No, single record only",
          description: "Optimize for single record operations"
        }
      ],
      multiSelect: false
    },
    {
      question: "When should the validation run?",
      header: "Timing",
      options: [
        {
          label: "Before insert",
          description: "Prevent invalid data from being saved"
        },
        {
          label: "Before update",
          description: "Validate changes to existing records"
        },
        {
          label: "Both",
          description: "Run on insert and update"
        }
      ],
      multiSelect: false
    }
  ]
})
```

#### Question Topics to Consider

**Data Model**:
- What fields are required?
- What relationships exist?
- What are the lookup/master-detail needs?

**Automation**:
- Real-time (trigger) or scheduled (batch)?
- Single vs bulk processing?
- Synchronous or asynchronous?

**Security**:
- Who needs access?
- Field-level security requirements?
- Sharing rules needed?

**Integration**:
- Which external systems?
- Real-time or batch?
- Authentication method?

**User Interface**:
- Standard page layouts or custom LWC?
- Desktop, mobile, or both?
- What actions should users perform?

#### Incorporate Into Decisions

User answers become part of the solution decisions — not stored separately. The decision captures the "what" and "why" together.

Example: If user confirms "bulk support required" → Decision becomes: "Use bulkified trigger pattern (user confirmed 200+ record volume)"

**Do NOT proceed to Phase 3 with unresolved ambiguities.**

---

### Phase 3: Discover Context

**Goal**: Understand existing project patterns and constraints.

#### Step 1: Check Framework Context

Look for project documentation:

```
Glob: .claude/context/**/*.md
```

Key files to check if they exist:
- `.claude/context/ProjectOverview.md` — project description
- `.claude/context/ObjectModel.md` — existing objects
- `.claude/context/Automations.md` — existing automation patterns
- `.claude/context/UIComponents.md` — LWC patterns
- `.claude/context/SecurityModel.md` — security architecture

#### Step 2: Explore Codebase (if context insufficient)

Use tools to discover patterns:

```
Glob: force-app/**/classes/*.cls          # Find Apex classes
Glob: force-app/**/objects/*              # Find custom objects
Glob: force-app/**/lwc/*                  # Find LWC components
Grep: "class.*Service|class.*Selector"    # Service/selector patterns
Grep: "[keywords from user story]"        # Related code
```

#### Step 3: Identify Reuse Opportunities

Look for:
- Existing objects that can be extended
- Utility classes to leverage
- Common patterns to follow
- Naming conventions to match

**Output**: Related objects, existing patterns, reuse opportunities.

---

### Phase 4: Design Solution

**Goal**: Create structured solution with clear decisions.

#### Solution JSON Structure

```json
{
  "summary": "1-2 sentence solution description",

  "decisions": [
    {
      "decision": "Use Trigger with Service Layer instead of Flow",
      "rationale": "Complex conditional logic with multiple objects requires programmatic control",
      "alternatives_considered": [
        "Record-Triggered Flow - too limited for complex logic",
        "Platform Event - overkill for synchronous operation"
      ],
      "impact": "Better testability and maintainability"
    }
  ],

  "objects": [
    {
      "name": "CustomObject__c",
      "label": "Custom Object",
      "purpose": "Store X data for Y process",
      "fields": [
        {
          "name": "FieldName__c",
          "type": "Text(255)",
          "required": true,
          "purpose": "Track X information"
        }
      ],
      "relationships": [
        {
          "type": "Lookup",
          "to": "Account",
          "purpose": "Link to parent account"
        }
      ]
    }
  ],

  "apex": [
    {
      "name": "ServiceClassName",
      "type": "Service",
      "purpose": "Business logic for X process",
      "methods": [
        {
          "name": "methodName",
          "purpose": "Handle X operation",
          "parameters": "List<SObject> records",
          "returns": "void"
        }
      ],
      "dependencies": ["SelectorClass", "UtilityClass"]
    }
  ],

  "lwc": [
    {
      "name": "componentName",
      "purpose": "UI for X feature",
      "features": ["Display data", "Handle user input", "Call Apex"],
      "wireServices": ["@wire(getRecord)", "@wire(getObjectInfo)"],
      "apexMethods": ["ServiceClassName.methodName"]
    }
  ],

  "permissions": [
    {
      "name": "PermissionSetName",
      "label": "Permission Set Label",
      "grants": [
        "Read/Write on CustomObject__c",
        "Execute ApexClass ServiceClassName"
      ]
    }
  ],

  "tests": [
    {
      "name": "ServiceClassNameTest",
      "purpose": "Test X functionality",
      "scenarios": [
        "Single record success",
        "Bulk records (200+)",
        "Negative cases",
        "Governor limit safety"
      ]
    }
  ]
}
```

#### Design Guidelines

**Architecture**:
- Service Layer for business logic (not in triggers)
- Selector pattern for SOQL queries
- Triggers delegate to services immediately
- Keep triggers thin (max 10 lines)

**Security**:
- Permission Sets over Profile modifications
- Field-level security via Permission Sets
- WITH SECURITY_ENFORCED in SOQL
- User mode enforcement

**Performance**:
- Bulkification patterns (handle 200+ records)
- Avoid SOQL in loops
- Use collections for governor limit safety
- Consider async processing for heavy operations

**Testing**:
- 100% code coverage minimum
- Test bulk scenarios (200+ records)
- Test negative cases
- Test governor limit scenarios

---

### Phase 5: Self-Validate (Design-Level)

**Goal**: Challenge your own solution for design issues.

#### 5.1 Pattern Consistency Check

Compare with existing codebase patterns:
- Does naming follow project conventions?
- Are there existing utilities to reuse?
- Does architecture match existing layers?

Use Grep to find similar patterns:
```
Grep: "class.*Service"   # Find service layer pattern
Grep: "class.*Selector"  # Find selector pattern
```

#### 5.2 Duplicate Detection

Check for conflicts with existing components:

```
Glob: **/objects/{ProposedObjectName__c}*
Glob: **/classes/{ProposedClassName}*
Glob: **/lwc/{proposedComponentName}*
```

If duplicates found → update solution to extend or rename.

#### 5.3 Dependency Check

Verify references are valid:
- If creating lookup field → does parent object exist?
- If extending existing class → does it exist?
- If using custom permission → is it defined?

Mark dependencies as "existing" or "to be created".

#### 5.4 Security Review

Check for security considerations:
- Are sharing rules needed?
- Is field-level security defined?
- Are there integration user permissions?

#### 5.5 Performance Analysis

Review for governor limits:
- SOQL queries in loops?
- DML operations in loops?
- Heap size considerations for bulk operations?

**If issues found**: Update solution inline, document what was changed and why.

> **Note**: Detailed code-level validation happens in dev-agent with sf-apex skill.

---

### Phase 6: Generate Outputs

**CRITICAL: Keep output concise and dry. This is a technical blueprint for implementation, not documentation.**

- Use bullet points, not paragraphs
- State facts and decisions, not explanations
- Focus on WHAT to implement, not WHY (unless critical)
- Think "implementation checklist", not "design document"

#### Output 1: Markdown Summary (for human review)

```markdown
# Solution: [Feature Name]

## Summary
[1 sentence: What we're building]

## Key Decisions 💡
- **[Decision]**: [What] — [Why in 1 sentence]

## Components

### Objects
- **ObjectName__c**
  - Field1__c (Text(255), required)
  - Field2__c (Lookup to Account)
  - Trigger: ObjectNameTrigger

### Apex
- **ServiceName** (Service)
  - `processRecords(List<SObject>)` — business logic
  - Bulkified, governor limit safe
- **ServiceNameTest** (Test)
  - Bulk scenarios (200+), negative cases

### LWC
- **componentName**
  - @wire getRecord
  - Calls ServiceName.methodName
  - Mobile-ready, SLDS

### Permissions
- **PermissionSetName**
  - R/W on ObjectName__c
  - Execute ServiceName

## Files

**Create:**
- objects/ObjectName__c/ObjectName__c.object-meta.xml
- objects/ObjectName__c/fields/Field1__c.field-meta.xml
- classes/ServiceName.cls
- classes/ServiceNameTest.cls
- lwc/componentName/componentName.js

**Edit:**
- classes/ExistingService.cls (add X method)

## Validation
✅ No conflicts | ✅ Dependencies OK | ✅ Patterns match | ✅ Governor safe
```

**Keep it SHORT. Implementation details go in JSON, not markdown.**

#### Output 2: Structured JSON

Full JSON object for dev-agent consumption (see Phase 4 structure).

#### Output 3: Implementation Checklist

```yaml
files_to_create:
  - force-app/main/default/objects/ObjectName__c/ObjectName__c.object-meta.xml
  - force-app/main/default/objects/ObjectName__c/fields/FieldName__c.field-meta.xml
  - force-app/main/default/classes/ServiceClassName.cls
  - force-app/main/default/classes/ServiceClassName.cls-meta.xml
  - force-app/main/default/classes/ServiceClassNameTest.cls
  - force-app/main/default/classes/ServiceClassNameTest.cls-meta.xml
  - force-app/main/default/lwc/componentName/componentName.js
  - force-app/main/default/lwc/componentName/componentName.html
  - force-app/main/default/lwc/componentName/componentName.js-meta.xml

files_to_edit:
  - force-app/main/default/classes/ExistingService.cls

tests_to_create:
  - ServiceClassNameTest.cls (bulk scenarios, negative cases, governor limits)
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Ambiguous requirements | Use Clarification Wizard (Phase 2) |
| No context files | Explore codebase, document assumptions |
| Conflicting patterns in codebase | Propose most common pattern, flag alternatives |
| Self-validation failures | Fix in solution, document the change |
| User cancels wizard | Ask if they want to proceed with assumptions |

---

## Tips

1. **Clarify first**: Ambiguity caught now saves rework later
2. **Use the wizard**: Interactive questions are better than assumptions
3. **Be concise**: Implementation checklist, not design essay
4. **Reuse first**: Check existing components before proposing new
5. **Self-critique honestly**: Better to find design issues now than in code review
6. **Keep it focused**: This skill blueprints; dev-agent implements
7. **DRY output**: State facts and decisions, skip explanations unless critical

---

## Integration Points

**Called by**:
- `sf-solution-jira` skill (orchestration layer)
- Main chat (direct skill invocation)

**Calls**:
- `AskUserQuestion` (clarification wizard)
- `Read`, `Glob`, `Grep` (context discovery)

**Output consumed by**:
- `dev-agent` (implementation)
- User (human review)
- Jira (via sf-solution-jira skill)

---

## Example Usage

### Example 1: Direct invocation

User: "Design a solution for tracking customer feedback"

→ Parse requirements
→ Use wizard to clarify (volume, security, UI needs)
→ Discover context
→ Design solution
→ Self-validate
→ Output markdown + JSON

### Example 2: Called by sf-solution-jira

sf-solution-jira passes Jira story text:

→ Skip fetching (already provided)
→ Parse Jira description
→ Use wizard for missing details
→ Design solution
→ Return to sf-solution-jira for posting to Jira

### Example 3: With existing context

User provides requirements + points to .claude/context/

→ Parse requirements
→ Read context files
→ Match patterns from context
→ Design solution aligned with project architecture
