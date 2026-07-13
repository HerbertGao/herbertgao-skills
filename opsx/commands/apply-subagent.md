---
description: 以编排模式实现 OpenSpec 变更——按范围分组、每组派 subagent 开发、主 agent 只做状态管理与 review（实验性）
argument-hint: "[change-name]"
---

以**编排模式**实现 OpenSpec 变更中的任务。

**输入**：`$ARGUMENTS` —— 可选的变更名称（例如 `/opsx:apply-subagent add-auth`）。如果为空，检查是否能从对话上下文推断；模糊或不明确时必须提示可用变更。

**执行方式**

调用 `opsx:openspec-apply-change-subagent` skill，并把 `$ARGUMENTS`（若有）作为目标变更名传入。该 skill 是本工作流的唯一事实来源（SOT），完整定义了：

- 主 agent 作为**编排者**：选变更、跑 `openspec-cn` 状态/指令、读上下文文件、分组、派发 subagent、review、报告进度、建议归档——**不亲自写实现代码**
- 按**范围**（子项目 / 模块 / 技术栈）对待处理任务分组，判断组间依赖
- **先并行后串行**派发 subagent 实现各组任务：每组先按四层解析梯（registered → local → fetched → embedded）解析一位实现专家（前端 / 后端 / 数据 / 基础设施 / 通用小修），未注册的专家以其 persona 注入 `general-purpose`
- 复选框 `- [x]` 由主 agent 独占标记（subagent 只读任务文件，避免并行组互相覆盖）
- review 粒度按是否跨子项目判断：跨则分项目 review，否则统一 review；不通过派修复 subagent 并重新 review

严格按该 skill 的步骤、输出格式与护栏执行。

**与原版 `/opsx:apply` 的区别**

`/opsx:apply` 是 OpenSpec 原版命令（主 agent 自己逐个任务循环实现），**不随本 plugin 分发**——本 plugin 只提供 `/opsx:apply-subagent` 这一编排版（主 agent 编排、subagent 分组开发）。若你本地另装了原版，两者可并存、按需选用。
