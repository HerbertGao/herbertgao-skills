---
description: 以编排模式实现 OpenSpec 变更——按范围分组、每组派 cursor-agent（composer-2.5）当编码 worker、主 agent 做状态管理；全部编码完成后挂一次 review-loop（实验性）
argument-hint: "[change-name]"
---

以**编排模式**实现 OpenSpec 变更中的任务，**用 cursor-agent 当编码 worker**（走 cursor 订阅额度，比 Claude subagent 更快更省）。

**输入**：`$ARGUMENTS` —— 可选的变更名称（例如 `/opsx:apply-cursor add-auth`）。如果为空，检查是否能从对话上下文推断；模糊或不明确时必须提示可用变更。

**执行方式**

调用 `opsx:openspec-apply-change-cursor` skill，并把 `$ARGUMENTS`（若有）作为目标变更名传入。该 skill 是本工作流的唯一事实来源（SOT），完整定义了：

- **步骤 0 doctor 前置**：开跑前校验 cursor-agent 在 PATH 且已登录、sub-agents-skills 的 `run_subagent.py` 可定位、默认模型 composer-2.5、非 root；任一不满足报错 + 修复指令并停止，不默默退化
- 主 agent 作为**编排者**：选变更、跑 `openspec-cn` 状态/指令、读上下文文件、按范围分组、**经壳 subagent `runner:sub-agent-runner` 派发 cursor worker（壳不可用 fallback Bash shell-out `run_subagent.py`）**、解析双层返回、补标遗漏复选框、收尾 review、报告进度、建议归档——**不亲自写实现代码**
- 按**范围**（子项目 / 模块 / 技术栈）对待处理任务分组，判断组间依赖；组粒度 3–8 任务（过大易超时要拆小）
- **先并行后串行**派发 cursor worker（壳路径用多个 Agent 调用并发、fallback 用 Bash `run_in_background`）实现各组任务
- 复选框 `- [x]` 由 cursor worker 自己标记，主 agent 仅补漏
- review 方式：**全部编码完成后挂一次 `review-loop`**（提案 + 全部代码 diff），不通过由 review-loop 自身修复循环处理；必要时把某组修复 spec 重新下放给 cursor worker

严格按该 skill 的步骤、输出格式与护栏执行。

**前置条件**

- `cursor-agent` 已安装并 `cursor-agent login` 登录（默认模型 composer-2.5）
- 已安装 `sub-agents-skills`：`/plugin marketplace add shinpr/sub-agents-skills` 然后 `/plugin install runner@sub-agents-skills`——它提供 worker 派发用的 `run_subagent.py`
- `openspec-cn` CLI 可用

**与其它 apply 命令的区别**

- `/opsx:apply-subagent`：worker 是 Claude subagent（`Task(general-purpose)`），每组/分项目 review。
- `/opsx:apply-cursor`（本命令）：worker 是 cursor-agent（更快更省），收尾挂一次 review-loop。
- 三者（连同 OpenSpec 原版 `/opsx:apply`）**并存**，按需选用，互不覆盖。
