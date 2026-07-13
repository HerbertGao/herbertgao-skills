---
name: openspec-apply-change-subagent
description: 以编排模式实现 OpenSpec 变更——主 agent 把任务按范围分组、每组派 subagent 开发、自己只做状态管理与 review。当用户想用 subagent 分组方式开始/继续实现任务时使用。这是 openspec-apply-change 的并存定制版，不覆盖原 skill。
license: MIT
compatibility: 需要 openspec-cn CLI。
metadata:
  author: openspec
  generatedBy: "1.6.0"
  basedOn: "openspec-apply-change (1.6.0)"
  customization: "相对原版 apply（主 agent 逐任务循环实现），改为主 agent 编排：按范围分组、每组派 subagent 实现并 review。"
---

实现 OpenSpec 变更中的任务。

**角色模型（本定制版的核心）**

主 agent 是**编排者（orchestrator）**，不亲自写实现代码：

- **主 agent 负责**：选变更、跑 `openspec-cn` 状态/指令、读上下文文件、把任务按范围分组、派发 subagent、review subagent 产出、报告进度、建议归档。
- **subagent 负责**：每组任务的具体编码实现。**它不碰任务文件**——完成了哪几条，在返回 JSON 的 `completed[]` 里逐字列出。
- **任务文件的复选框由主 agent 独占写入**：并行的多个 subagent 编辑同一个任务文件会读-改-写互相覆盖（丢标记）；而主 agent 本来就要亲自核对每条任务才认可完成，标记权留在它手里既根治竞态、又与该护栏一致。任何成规模的编码都必须下放给 subagent。

**输入**：可选指定变更名称。如果省略，检查是否可以从对话上下文中推断。如果模糊或不明确，你**必须**提示获取可用变更。

**Store 选择**：如果用户指定了某个 Store（在本机注册的独立 OpenSpec 仓库），或工作位于某个 Store 中，先运行 `openspec-cn store list --json` 查到 Store ID，然后在读写规范/变更的命令上带 `--store <id>`（`list`、`status`、`instructions`、`archive` 等）。本编排版的所有 `openspec-cn` 调用都由主 agent 发出，故 `--store <id>` 只需主 agent 携带，subagent 不跑这些命令。未指定 Store 时对最近的本地 `openspec/` 根目录生效。

**步骤**

1. **选择变更**

   如果提供了名称，使用它。否则：
   - 如果用户提到了某个变更，从对话上下文中推断
   - 如果只存在一个活动变更，自动选择
   - 如果不明确，运行 `openspec-cn list --json` 获取可用变更，并使用 **AskUserQuestion tool** 让用户选择

   始终宣布："正在使用变更：<name>"以及如何覆盖（例如，`/opsx:apply-subagent <other>`）。

2. **检查状态以了解 Schema**
   ```bash
   openspec-cn status --change "<name>" --json
   ```
   解析 JSON 以了解：
   - `schemaName`：正在使用的工作流 Schema（例如："spec-driven"）
   - 哪个产出物包含任务（对于 spec-driven 通常是 "tasks"，检查其他产出物的状态）

3. **获取应用指令**

   ```bash
   openspec-cn instructions apply --change "<name>" --json
   ```

   这返回：
   - `contextFiles`：产出物 ID -> 具体文件路径数组（因 Schema 而异，可能是 proposal/specs/design/tasks 或 spec/tests/implementation/docs）
   - 进度（总计、完成、剩余）
   - 带有状态的任务列表
   - 基于当前状态的动态指令

   **处理状态：**
   - 如果 `state: "blocked"`（缺少产出物）：显示消息，建议使用 `openspec-continue-change`
   - 如果 `state: "all_done"`：祝贺，建议归档
   - 否则：继续实现

4. **阅读上下文文件**

   主 agent 必须亲自阅读 apply instructions 输出中 `contextFiles` 列出的每个文件路径——这是后续分组与 review 的依据。
   文件取决于正在使用的 Schema：
   - **spec-driven**: proposal, specs, design, tasks
   - 其他模式：遵循 CLI 输出中的 contextFiles

5. **按范围对待处理任务分组**

   分析 `state` 不为完成的所有任务，按**范围**把它们分成若干组：

   - **范围 = 任务所触及的子项目 / 模块 / 技术栈**。典型边界：Java 端 / Rust 端 / React 端；backend / frontend / infra；或不同的 capability / spec 区域。
   - 每个任务归入它主要改动的那个范围；跨范围的任务归入其"主战场"，并在 subagent prompt 里点明它需要兼顾的另一侧。
   - 组的粒度以 3–8 个任务为宜：太碎的组合并，过大的组再拆。
   - **判断组间依赖**：若 B 组的任务依赖 A 组的产出（例如前端要调用后端本次新增的 API、测试依赖被测代码先就位），则记 A → B。无此关系的组互相独立。
   - 把分组结果和依赖关系展示给用户（见下方"分组方案输出"），然后继续。

   若全部待处理任务本就属于同一范围且无法有意义地切分，则视为**单组**，直接进入下一步（仍走 subagent 派发）。

6. **派发 subagent 实现（先并行后串行）**

   按拓扑顺序派发。**每组先解析一位实现专家**（角色注册表见下「实现专家与解析梯」），再派发：

   - **并行**：当前所有前置依赖已满足的组，在**同一条消息里发出多个 Agent 调用**并发执行。
   - **串行**：有依赖的组等其前置组的 subagent 全部返回后，再发出下一批。
   - 重复直到所有组都已派发完。

   每个 subagent 的 prompt **必须**包含：
   - 变更名称与 Schema
   - 该组负责的**完整任务清单**（逐条列出任务原文）
   - 相关上下文文件的**绝对路径**（proposal / specs / design / tasks 等），要求 subagent 自己阅读
   - 任务文件的路径**仅供阅读**，并明确约定：**不要编辑任务文件、不要改任何复选框**——完成的任务逐字写进返回 JSON 的 `completed[]`，由主 agent 统一标记（并行组共写同一文件会互相覆盖）
   - 约束：保持改动最小且限定在本组范围内；**不要碰其他组负责的任务**；遇到不清楚的需求或设计问题不要猜测，停下来在返回信息中说明
   - 要求 subagent 在最终返回中**只输出一个 JSON 对象**（放进 ```json 代码块），严格遵循下方「Subagent 返回契约」的 schema——主 agent 靠解析这个 JSON 判断进度、决定 review 粒度、决定是否暂停；不要夹杂自由文本散叙。

7. **Review subagent 产出**

   review 粒度按任务跨度判断：

   - **跨多个子项目**（各组分属不同子项目 / 技术栈，如 Java 端、Rust 端、React 端）：**每个子项目分别 review**——逐个子项目读其改动文件、对照该范围的任务验收。
   - **未跨子项目**（任务集中在单一项目 / 技术栈内）：**统一 review** 全部产出。

   先解析每个 subagent 返回的 JSON：若任一组 `needsAttention: true`（`incomplete` 或 `issues` 非空），**不要直接判 review 通过**——按步骤 8 的暂停流程把问题摊给用户。其余组再走文件级 review。

   主 agent 亲自做 review：以返回 JSON 的 `filesChanged` 为线索阅读 subagent 改动过的文件，对照 `completed` 中逐字引用的任务原文与上下文文件中的规格，对照现有契约与测试，检查是否真正满足、有无遗漏、有无越界改动（JSON 是导航，不替代读真实 diff）。

   - review **通过**：主 agent 按该组 `completed[]` 里的任务原文，把任务文件中对应的 `- [ ]` 逐条改为 `- [x]`（**只有主 agent 写这个文件**，因此不存在并发覆盖）。
   - review **不通过**：派一个修复 subagent，prompt 里给出明确 spec（问题所在文件、具体问题、期望结果、验收方式）。修复返回后**重新 review**，直到通过。

8. **完成或暂停时，显示状态**

   再次运行 `openspec-cn instructions apply --change "<name>" --json` 核对进度，然后显示：
   - 本次会话完成的任务
   - 总体进度："N/M 任务已完成"
   - 如果全部完成：建议归档
   - 如果暂停：解释原因并等待指导

**Subagent 返回契约**

每个实现 / 修复 subagent 的最终返回必须是**唯一一个** JSON 对象（包在 ```json 代码块里），无前后散文，schema 如下：

```json
{
  "group": "组名（范围）",
  "schema": "回显本次 Schema 名（如 spec-driven），确认 subagent 读对了上下文",
  "completed": [
    { "task": "任务文件中的原文（逐字引用）" }
  ],
  "incomplete": [
    { "task": "任务原文（逐字）", "reason": "未完成原因" }
  ],
  "filesChanged": [
    { "path": "绝对路径", "summary": "本次改动要点" }
  ],
  "issues": [
    {
      "kind": "ambiguous-requirement | design-issue | error | out-of-scope | blocker",
      "detail": "具体描述",
      "relatedTask": "任务原文 或 null"
    }
  ],
  "needsAttention": false
}
```

约定：

- `needsAttention` 为 `true` **当且仅当** `incomplete` 或 `issues` 非空。**主 agent 不信任这个字段：自己按 `incomplete`/`issues` 是否非空重算**——畸形返回（`issues` 非空却自报 `false`）否则会被当成可 review 的产出直接放行。重算为 `true` ⇒ 按步骤 8 暂停，不得直接判该组 review 通过。
- `completed[].task` 必须逐字引用任务文件原文——主 agent 靠它定位要标记的那一行。subagent **不标记、不编辑任务文件**。
- subagent 遇到模糊需求 / 设计问题 / 报错 / 越界 时，**不要猜测**——把它记进 `issues` 并停下该条任务，由主 agent 决定。
- 主 agent 在 prompt 里把这份 schema 原样贴给 subagent，不让其自行约定返回格式。

**实现专家与解析梯**

按组的范围选专家（逻辑角色来自 [agency-agents](https://github.com/msitarzewski/agency-agents)；`subagent_type` = 其 frontmatter `name:`）：

| 实现分组 | 逻辑角色 | agency-agents 源路径 |
|---|---|---|
| 前端 | `Frontend Developer` | `engineering/engineering-frontend-developer.md` |
| 后端 / API | `Backend Architect` | `engineering/engineering-backend-architect.md` |
| 数据 / 数据库 | `Data Engineer` / `Database Optimizer`（涉及查询计划、索引或 schema 迁移时选后者；两者都涉及时并行各派一个） | `engineering/engineering-data-engineer.md` / `engineering/engineering-database-optimizer.md` |
| 基础设施 | `DevOps Automator` | `engineering/engineering-devops-automator.md` |
| 通用小修 | `Minimal Change Engineer` | `engineering/engineering-minimal-change-engineer.md` |

每组按四层解析（回显解析到的层级，`embedded` 层的组 review 时加严）：

1. **registered** —— `subagent_type` 已注册 → 直接派发（最强层）。
2. **local** —— `~/.agency-agents/<slug>.md` 或 `find ~/.agency-agents -type f -name '*<slug>*.md'`（最深嵌套两层）；校验 frontmatter `name:`，正文（跳过 frontmatter）作 persona 注入 `general-purpose`。
3. **fetched** —— 本地缺失 → 从 jsDelivr 拉上表源路径入 `~/.agency-agents/` 并校验（`---` frontmatter + `name:`），再按 local 用：`mkdir -p ~/.agency-agents && curl -fsSL --max-time 10 https://cdn.jsdelivr.net/gh/msitarzewski/agency-agents@main/<源路径> -o ~/.agency-agents/<slug>.md`（`-o` 是关键：不写入缓存路径，下一层就找不到它）。校验失败删缓存、落下一层。
**供应链说明**：`fetched` 拉的是 `agency-agents@main`（可变），frontmatter 校验只验形状不验来源。它是便利层——不信任远程内容的环境应预先 `git clone` 目录（让 `local` 先命中），或依赖 `embedded`（其 prompt 随本文件分发）。

4. **embedded** —— 网络不可用 → 内嵌浓缩 prompt（更弱的专家；review 加严）：前端「你是前端开发者。用现代 Web 技术实现该任务，遵循代码库现有模式，兼顾可访问性与响应式设计。」后端「你是后端架构师。按现有 API 模式、错误处理约定和数据模型实现该任务，保证向后兼容。」数据「你是数据工程师。按现有 schema 约定、迁移模式和查询优化实践实现该任务。」基础设施「你是 DevOps 自动化工程师。按现有 IaC 模式、CI/CD 约定和部署实践实现该任务。」通用小修「你是最小修改工程师。只用最小可能的 diff 实现指定任务；除非任务明确要求，不加抽象、配置、依赖或特性；不碰无关代码。」

**分组方案输出（步骤 5 后）**

```
## 任务分组：<change-name>（Schema：<schema-name>）

待处理任务 M 个，按范围分为 K 组：

- **组 A — <范围名>**（N 个任务）：任务 1, 2, 5
- **组 B — <范围名>**（N 个任务）：任务 3, 4
- **组 C — <范围名>**（N 个任务）：任务 6, 7

依赖：组 A、组 B 独立 → 并行；组 C 依赖组 A → 待组 A 完成后执行。
```

**派发与实现期间的输出**

```
## 正在实现：<change-name>（Schema：<schema-name>）

▶ 并行派发：组 A、组 B
  ✓ 组 A subagent 返回：完成任务 1, 2, 5
  ✓ 组 B subagent 返回：完成任务 3, 4
▶ 串行派发：组 C（依赖组 A）
  ✓ 组 C subagent 返回：完成任务 6, 7

▶ Review（跨子项目，分项目 review）
  ✓ Java 端：通过
  ✓ React 端：通过
```

**完成时的输出**

```
## 实现完成

**变更：** <change-name>
**Schema：** <schema-name>
**进度：** 7/7 任务已完成 ✓

### 本次会话已完成（按组）
- 组 A：[x] 任务 1、[x] 任务 2、[x] 任务 5
- 组 B：[x] 任务 3、[x] 任务 4
- 组 C：[x] 任务 6、[x] 任务 7

### Review 结论
<分项目 / 统一 review 的结论>

所有任务已完成！准备归档此变更。
```

**暂停时的输出（遇到问题）**

```
## 实现暂停

**变更：** <change-name>
**Schema：** <schema-name>
**进度：** 4/7 任务已完成

### 遇到的问题
<来自某个 subagent 返回的问题 / review 未通过的问题>

**选项：**
1. <选项 1>
2. <选项 2>
3. 其他方法

您想怎么做？
```

**护栏**
- 主 agent 不亲自写实现代码——所有成规模的编码都派 subagent；主 agent 只做编排、状态管理与 review
- 开始前主 agent 始终亲自阅读上下文文件（来自 apply instructions 输出）
- 分组依据是"范围"（子项目 / 模块 / 技术栈），不是任务序号；先并行后串行，依赖关系由主 agent 判断
- 派 subagent 时把完整任务清单、上下文文件绝对路径、约定一次性写清楚——不让 subagent 自己揣测范围
- subagent 返回必须是符合「Subagent 返回契约」的单个 JSON 对象；主 agent 解析它驱动 review 与暂停决策，`needsAttention: true` 一律先暂停问人，不直接判通过
- 复选框 `- [x]` **只由主 agent 写**（review 通过后按 `completed[]` 逐条标记）；subagent 只读任务文件、不编辑——并行组共写同一文件会丢标记
- review 粒度按是否跨子项目判断：跨则分项目 review，否则统一 review；review 不通过派修复 subagent 并重新 review
- 任务模棱两可、揭示设计问题、遇到错误或阻碍时暂停——不要猜测
- 使用 CLI 输出中的 contextFiles，不要假设特定的文件名
- 进度报告中注明每组专家解析到的层级（registered/local/fetched/embedded）；`embedded` 层的组 review 加严——浓缩 prompt 是比完整 agency-agents 原文更弱的专家

**流畅的工作流集成**

此技能支持"变更上的操作"模型：

- **可以随时调用**：在所有产出物完成之前（如果存在任务），部分实现之后，与其他操作交错
- **允许产出物更新**：如果某个 subagent 的返回揭示了设计问题，主 agent 应暂停并建议更新产出物 - 不是阶段锁定的，流畅地工作
