---
description: 以 OpenCode subagent 编排实现 OpenSpec 变更：按范围分组、委派实现、主 agent 只做状态管理与 review
---

以编排模式实现 OpenSpec 变更中的任务。

输入：`$ARGUMENTS` 是可选变更名称，例如：

```text
/opsx-apply-subagent add-auth
```

执行方式：

1. 加载并遵循 `openspec-apply-change-subagent` skill。
2. 把 `$ARGUMENTS` 作为目标变更名传入；为空时按 skill 的选择规则推断或询问。
3. 使用 OpenCode subagents，不使用 Codex subagents、Claude `subagent_type` 或 `codex:codex-rescue`。
4. 按范围分组任务，使用 OpenCode `@...` agents 委派实现，主 agent 只做 `openspec-cn` 状态管理、上下文阅读、review 与进度报告。

常用委派映射：

- `@engineering-frontend-developer`
- `@engineering-backend-architect`
- `@engineering-data-engineer`
- `@engineering-devops-automator`
- `@engineering-minimal-change-engineer`
