---
description: 以编排模式实现 OpenSpec 变更——按范围分组、每组派 subagent 开发、主 agent 只做状态管理与 review（实验性）
argument-hint: "[change-name]"
---

调用 `openspec-apply-change-subagent` skill 实现 OpenSpec 变更：$ARGUMENTS

该 skill 是本工作流的唯一事实来源（SOT）——严格按它执行，不要在这里复述它的规则。

一句话形状：**每一道校验的证据，都必须来自一个被检查方没有撰写的产物。** `filesChanged` 是 subagent 自己写的，只能导航；地面真相来自主 agent 自己跑的**树快照 diff**（`git write-tree`）；**归因靠隔离**——每组一个 worktree，或者串行到一波只有一个写者，因为共享树上 git 只知道「哪些文件被改了」，永远不知道「谁改的」；「能不能跑」靠 build/test 的退出码。
