---
name: openspec-apply-change-subagent
description: Apply an OpenSpec change in Codex by grouping pending tasks by scope, delegating implementation to Codex subagents, and keeping the main agent focused on openspec-cn state, context reading, review, and final progress reporting.
---

# openspec-apply-change-subagent for Codex

Implement OpenSpec change tasks through orchestration.

## Platform Adapter

This is the Codex port.

- Use Codex subagent workflows only.
- Do not use Claude Code `Agent tool`, `Task tool`, or `subagent_type`.
- Do not use OpenCode `@agent` syntax.
- The main agent is the orchestrator and should not write substantial implementation code.
- Implementation groups should be delegated to Codex `worker` subagents or to an installed agency-agents custom agent whose role clearly matches the group.
- If custom agents are not visible in the current runtime, use Codex `worker` with an explicit role prompt.

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

Read `schemaName` and locate the artifact that contains tasks.

2. Fetch apply instructions:

```bash
openspec-cn instructions apply --change "<name>" --json
```

Handle states:

- `blocked`: report missing artifacts and suggest continuing the change definition.
- `all_done`: report completion and suggest archive.
- otherwise continue.

3. Read context files yourself.

Read every file listed in `contextFiles` before grouping or delegation. Do not assume fixed filenames; follow CLI output.

4. Group pending tasks by scope.

Scope means subproject, module, technology stack, capability area, or ownership boundary. Prefer groups of 3-8 tasks. Identify dependencies between groups and produce:

```text
## 任务分组：<change-name>（Schema：<schema-name>）

待处理任务 M 个，按范围分为 K 组：

- 组 A — <范围名>（N 个任务）：任务 1, 2, 5
- 组 B — <范围名>（N 个任务）：任务 3, 4

依赖：组 A 独立；组 B 依赖组 A。
```

5. Delegate implementation.

Dispatch all dependency-ready groups in parallel. Use serial waves when dependencies require it.

Each worker prompt must include:

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

Parse each JSON response. If any group reports `needsAttention: true`, pause and present the issue to the user before declaring progress complete.

For completed groups, read the changed files yourself. Use `filesChanged` only as navigation. Verify implementation against:

- Exact task text.
- Context files and specs.
- Existing contracts and tests.
- Scope boundaries.

If review fails, delegate a focused fix to a Codex worker or relevant custom agent with exact file paths, failure details, expected behavior, and verification steps. Re-review after the fix.

7. Confirm progress:

```bash
openspec-cn instructions apply --change "<name>" --json
```

Report completed tasks, total progress, review conclusion, and whether archive is ready.

## Guardrails

- Main agent handles OpenSpec state, grouping, delegation prompts, review, progress, and archive suggestion.
- Main agent may make tiny checkbox/status corrections only after review.
- All substantial implementation goes through Codex subagents.
- Do not assume Claude or OpenCode subagent APIs.
- Do not mark tasks complete based only on worker self-report; inspect files and task checkboxes.
- Pause on ambiguity, design conflict, or out-of-scope work.
