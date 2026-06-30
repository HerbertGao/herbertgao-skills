---
name: openspec-apply-change-subagent
description: Apply an OpenSpec change in OpenCode by grouping pending tasks by scope, delegating implementation to OpenCode subagents, and keeping the main agent focused on openspec-cn state, context reading, review, and progress reporting.
---

# openspec-apply-change-subagent for OpenCode

Implement OpenSpec change tasks through orchestration.

## Platform Adapter

This is the OpenCode port.

- Use OpenCode subagents only.
- Do not use Codex subagents or Codex custom agents.
- Do not use Claude Code `Agent tool`, `Task tool`, or `subagent_type`.
- Use OpenCode `@` slugs for installed agency-agents.
- Main agent is the orchestrator and should not write substantial implementation code.
- For implementation groups, choose an OpenCode subagent by scope:
  - Frontend: `@engineering-frontend-developer`.
  - Backend/API: `@engineering-backend-architect`.
  - Data/database: `@engineering-data-engineer` or `@engineering-database-optimizer`.
  - Infrastructure: `@engineering-devops-automator`.
  - Generic focused fix: `@engineering-minimal-change-engineer`.
- If no specialist fits, use a generic OpenCode subagent with the worker prompt and record `fallback`.

## Inputs

The user may provide a change name. If omitted:

1. Infer it from conversation when unambiguous.
2. If exactly one active change exists, use it.
3. Otherwise run:

```bash
openspec-cn list --json
```

Ask the user to choose only when the change cannot be safely inferred.

Always announce:

```text
正在使用变更：<name>
```

## Workflow

1. Inspect status:

```bash
openspec-cn status --change "<name>" --json
```

2. Fetch apply instructions:

```bash
openspec-cn instructions apply --change "<name>" --json
```

Handle `blocked`, `all_done`, and active implementation states according to the CLI output.

3. Read every file listed in `contextFiles` yourself before grouping or delegation.

4. Group pending tasks by scope: subproject, module, technology stack, capability area, or ownership boundary. Prefer groups of 3-8 tasks and identify dependencies.

Report:

```text
## 任务分组：<change-name>（Schema：<schema-name>）

待处理任务 M 个，按范围分为 K 组：

- 组 A — <范围名>（N 个任务）：任务 1, 2, 5
- 组 B — <范围名>（N 个任务）：任务 3, 4

依赖：组 A 独立；组 B 依赖组 A。
```

5. Delegate implementation.

Dispatch all dependency-ready groups in parallel when OpenCode supports it; otherwise run waves serially while preserving the dependency order.

Each subagent prompt must include:

- Change name and schema name.
- The complete task text for the group.
- Absolute paths to all relevant context files.
- The task file path.
- The rule: after completing a task, immediately change that task checkbox from `- [ ]` to `- [x]`.
- Scope boundary: do not edit other groups' tasks or checkboxes.
- Stop and report ambiguity, design issues, errors, or out-of-scope discoveries instead of guessing.
- Return exactly one JSON object in a fenced `json` block with this schema:

```json
{
  "group": "group name",
  "schema": "schema name",
  "completed": [
    { "task": "exact task text", "checkboxMarked": true }
  ],
  "incomplete": [
    { "task": "exact task text", "reason": "why incomplete" }
  ],
  "filesChanged": [
    { "path": "absolute path", "summary": "change summary" }
  ],
  "issues": [
    {
      "kind": "ambiguous-requirement | design-issue | error | out-of-scope | blocker",
      "detail": "specific detail",
      "relatedTask": "exact task text or null"
    }
  ],
  "needsAttention": false
}
```

6. Review worker output.

Parse each JSON response. If any group reports `needsAttention: true`, pause and present the issue to the user.

For completed groups, read changed files yourself. Use `filesChanged` only as navigation. Verify implementation against exact task text, context files, specs, existing contracts, tests, and scope boundaries.

If review fails, delegate a focused fix to the appropriate OpenCode subagent with exact file paths, failure details, expected behavior, and verification.

7. Confirm progress:

```bash
openspec-cn instructions apply --change "<name>" --json
```

Report completed tasks, total progress, review conclusion, and whether archive is ready.

## Guardrails

- Main agent handles OpenSpec state, grouping, delegation prompts, review, progress, and archive suggestion.
- Main agent may make tiny checkbox/status corrections only after review.
- All substantial implementation goes through OpenCode subagents.
- Do not mark tasks complete based only on subagent self-report; inspect files and task checkboxes.
- Pause on ambiguity, design conflict, or out-of-scope work.
