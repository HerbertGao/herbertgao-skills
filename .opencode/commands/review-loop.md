---
description: 对当前提案和代码变更运行 OpenCode 对抗性 review 循环，直到通过或达到轮数上限
---

加载并遵循 `review-loop` skill，对当前提案和代码变更运行 OpenCode 版对抗性 review 循环。

要求：

- 使用 OpenCode subagents，例如 `@engineering-code-reviewer`、`@testing-reality-checker`、`@engineering-minimal-change-engineer`。
- 不使用 Codex subagents、`codex:codex-rescue`、Claude `Agent tool` 或 `subagent_type`。
- 非终止轮次只回显标准状态行、triage 结论和修复摘要；只有终止轮次输出最终 token。
