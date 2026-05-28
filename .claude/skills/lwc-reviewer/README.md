# lwc-reviewer

Claude skill that reviews Lightning Web Components: it scores each bundle across five categories (bundle structure, JS quality, template and accessibility, performance, error handling and UX), then writes a structured markdown report under `code-review/`.

## Layout

| Path | Role |
|------|------|
| `SKILL.md` | Instructions, rubric, scoring, report naming |
| `references/lwc-naming-conventions.md` | Naming rules for JS reviews |
| `assets/review-result-template.md` | Report template |
| `evals/evals.json` | Test prompts and expected outcomes |
| `evals/files/` | Fixture LWC components used for evals |

## Eval execution

Running the skill **evaluation** workflow (benchmarking against `evals/evals.json`, using scripts such as `eval-viewer/generate_review.py`, and iterating on pass or fail criteria) requires the [**skill-creator**](https://github.com/anthropics/skills/tree/main/skills/skill-creator) skill from the Anthropic [`skills`](https://github.com/anthropics/skills) repository. Add that skill to your environment and follow its docs when you want automated eval runs or skill iteration loops.

**lwc-reviewer** alone is enough for **reviewing LWC components** in a project. **skill-creator** is only needed when you **execute or maintain** the eval pipeline described above.
