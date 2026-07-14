---
name: openspec-apply-change-subagent
description: 以编排模式实现 OpenSpec 变更——主 agent 把任务按范围分组、每组派 subagent 开发、自己只做状态管理与 review。当用户想用 subagent 分组方式开始/继续实现任务时使用。这是 openspec-apply-change 的并存定制版，不覆盖原 skill。需要 openspec-cn CLI（对齐 1.6.0）与 git（review 的地面真相来自它）。
---

实现 OpenSpec 变更中的任务。

## 证据规则（先读这一条——它是下面每条规则的形状）

主 agent 派发 subagent、review 它们的产出、写复选框、写进度报告。它只有一个动机：**把事情做完**。所以：

> **每一道校验的证据，都必须来自一个被检查方没有撰写的产物。**

| 产物 | 谁产出的 | 它证明什么 |
|---|---|---|
| **`ground`** —— `git status --porcelain -uall` 减去派发前的基线 | git | **真正被改的文件**。`filesChanged` 是 subagent 自己写的，只能当导航，不能当证据 |
| **每个 worker 自己那棵树的 diff**（隔离时）或**串行波次里唯一写者的 diff** | git | **谁改的**。在一棵共享的树上并行时，git 只知道「哪些文件被改了」，**永远不知道「谁改的」**——所以**并行必须隔离，否则串行**（步骤 6 ③）。写集是规划辅助，不是执法键 |
| **build / test 的退出码** | 编译器和测试 | **代码到底能不能跑**。复选框是主 agent 自己写的，`instructions apply` 读回来的正是它——自我确认，不是验证 |

三样以外的一切，都是自述。**唯一输入是被审方自报的检查不是检查。**

**角色模型**

- **主 agent** = 编排者：选变更、跑 `openspec-cn`、读上下文文件、分组并声明写集、派发、跑校验与 review、写复选框、跑集成门、报告。**它不写实现代码，但它运行命令**——跑 git / build / test 不违反这条护栏，那正是它的证据来源。
- **subagent** = 每组任务的编码实现。**它不碰任务文件、不碰 `openspec/` 下任何产出物、不跑任何改写 git 状态的命令。** 完成了哪几条，写进返回 JSON。
- **复选框只由主 agent 写。** 并行 subagent 编辑同一个任务文件会读-改-写互相覆盖（丢标记）；而主 agent 本来就要亲自核对每条任务才认可完成。**同样的单写者规则也适用于 git**：两个并行 subagent 各跑一次 `git stash`，丢的是对方的全部工作，且不可恢复。

**输入**：可选指定变更名称。省略则从对话上下文推断；模糊或不明确 ⇒ 必须提示获取可用变更。

**Store 选择**：用户指定了某个 Store（本机注册的独立 OpenSpec 仓库），或工作位于某个 Store 中 ⇒ 先跑 `openspec-cn store list --json` 查 Store ID，之后所有读写规范/变更的命令带 `--store <id>`（`list`/`status`/`instructions`/`validate`/`archive`）。**所有 `openspec-cn` 调用都由主 agent 发出**，故 `--store` 只需主 agent 携带。未指定 ⇒ 对最近的本地 `openspec/` 根目录生效。

## 步骤

### 1. 选择变更

有名称就用它。否则：从上下文推断 → 只有一个活动变更就自动选 → 仍不明确则 `openspec-cn list --json` 并让用户选。

始终宣布：「正在使用变更：`<name>`」，以及如何覆盖（重新调用本 skill 并指定变更名）。

### 2. 状态与指令

```bash
openspec-cn status --change "<name>" --json          # -> schemaName，哪个产出物含任务
openspec-cn instructions apply --change "<name>" --json   # -> contextFiles / progress / tasks / state
```

`tasks[]` 里每条任务带一个 **`id`（序号：`"1"`、`"2"`…）**——**它是后面标记复选框的唯一键**，不是 tasks.md 里的章节号 `1.2`。混淆这两者会静默标错行。

**处理 `state`：**

- `blocked`（缺少产出物）⇒ 显示消息，建议 `openspec-continue-change`。
- `all_done` ⇒ **不得直接建议归档**：先跑一次步骤 7 的集成门。`all_done` 读回来的是主 agent 自己写的复选框——自我确认，不是验证。门过了才恭喜、才建议归档。
- 否则 ⇒ 继续。

### 3. 阅读上下文文件

主 agent 亲自读 `contextFiles` 里的每个路径——这是后续分组与 review 的依据。文件因 Schema 而异（spec-driven：proposal / specs / design / tasks）。

### 4. 分组，并为每组声明写集

按**范围**（子项目 / 模块 / 技术栈；Java 端 / Rust 端 / React 端；backend / frontend / infra）把未完成任务分组，每组 3–8 个任务。

- **判断组间依赖**：B 组的任务依赖 A 组的产出（前端要调后端本次新增的 API、测试依赖被测代码先就位）⇒ 记 `A → B`。
- **跨范围的任务归入其主战场**，并在 prompt 里把另一侧标为「**只读，不得编辑**」。需要改另一侧 ⇒ 记进 `issues`（`kind: out-of-scope`）交主 agent 重新分组。让一个组去「兼顾另一侧」，就是让它和另一个组并行改同一批文件。
- **为每组声明写集**——它预期写入的**文件 / 目录前缀集**。这是**规划**用的：别把两个组放到同一批文件上。**它不是执法键**（步骤 6 ③——共享树上它抓不到「闯入并覆盖」）。
  - **写集两两相交的组不得并行**——合并成一组，或降级为串行波次。「范围」是任务上的启发式，**不是文件系统的分区**：后端组和前端组会常规地同时改一个共享类型定义、API client、路由表、i18n bundle、config。
  - **预测不出写集的组（跨切面重构、"重构鉴权中间件"这类）一律不并行**，走单组串行。猜大 ⇒ 什么都不能并行；猜小 ⇒ 静默竞态，而丢的是代码，不是标记。
  - **不是 git 仓库 ⇒ 没有地面真相 ⇒ 不得并行**：降级为单组串行，并在所有输出里注明「无执行性证据」。
- 全部任务本就同一范围且无法有意义切分 ⇒ **单组**，仍走 subagent 派发。

把分组、依赖和**每组的写集**展示给用户（见下方输出模板），然后继续。

### 5. 按波次派发（每波：派发 → 校验 → review → 标记 → 解锁下一波）

**每一波开始前，给工作树拍一个内容寻址的快照：**

```bash
TMPIDX=$(mktemp)                                   # 一个临时索引——绝不碰用户自己的 git index
snap(){ GIT_INDEX_FILE="$TMPIDX" git add -A >/dev/null && GIT_INDEX_FILE="$TMPIDX" git write-tree; }
BASE=$(snap)                                       # 波首
```

波末：`ground = git diff --name-only "$BASE" "$(snap)"`。

**为什么是树快照，不是「`git status` 相减」**：相减是在 porcelain 的**行**上做的，而**一个波首就已经脏的文件，波末还是那一行**——相减之后它**从 `ground` 里彻底消失**。实测后果：波次 2 的组把波次 1 已验收、已打勾的代码删掉，那个文件在波次 2 的基线里是脏的 ⇒ 被减掉 ⇒ **四道校验全绿、review 读不到它、集成门编译通过 ⇒ 归档，工作静默丢失。** 树快照是按**内容**比的，改了就是改了；它同时天然枚举新文件（不需要 `-uall`），也不产生「用户手头的活是盲区」这个副作用。

**并行的前提是隔离。**

- **有 per-worker 隔离**（每个 worker 一个独立 git worktree）⇒ 一波 = 写集不相交、依赖已满足的那些组，并发派发。**每组在自己的树里改**——所以：
  - 该组的 `ground` 是**它自己那棵树**的 diff：`git -C <wt> diff --name-only <该树的 BASE>`。**主树的 `git status` 里没有它**，在主树上跑校验会让每个诚实的组都判负。
  - **review 通过后必须合并回主树**，一组一组串行：`git -C <wt> diff <BASE> | git apply --3way`。**冲突就是碰撞**——当场可见、可回滚，而且这是共享树上永远得不到的那个信号。**没有这一步，代码留在一根一次性分支上，复选框却在主树上被打勾，集成门跑的是一棵没有实现的树。**
  - 合并完再标记复选框，再跑步骤 7。
- **没有隔离** ⇒ **一波一组，串行**。共享树上的并行没有诚实的碰撞证据源——`git` 只知道哪些文件被改了，不知道谁改的。串行时那一波只有一个写者，归因是平凡的。

（串行仍然拿到这个 skill 的全部价值：**上下文扇出**——每组一个干净的 subagent 上下文。并行买的是墙钟时间，代价是一个不成立的碰撞检测。）

- **串行的依赖组等前置组 review **通过**后才解锁——不是等它「返回」。** C 组踩着 A 组未经审查、可能是错的产出跑，是这个编排最贵的失败。
- 任一组校验或 review 不通过 ⇒ **停止派发后续波次**，按步骤 8 暂停。
- 重复直到所有组都**通过 review**，或中途暂停。

**每组先解析一位实现专家**（见「实现专家与解析梯」），再以 `subagent_type: general-purpose` 派发（未注册的专家把其正文作为 persona 注入）。**一组一 subagent、一组一返回。**

*（Claude Code 的 `Agent` 工具带 `isolation: "worktree"`——**并行组用它**：每个 worker 拿到独立的 git worktree，每组的 diff 天然可归因，「写集归因」从「够用」升级为「严密」，而且不需要基线相减。代价是每组约 200–500ms 建树开销。）*

**每个 subagent 的 prompt 必须包含：**

- 变更名称与 Schema；
- 该组的**完整任务清单**（每条带它的 `id` 和原文）；
- 上下文文件的**绝对路径**，要求 subagent 自己读；
- **该组的写集**，以及：改动限定在写集内，**不要碰其他组的任务或文件**；
- **任务文件仅供阅读**——不要编辑、不要改任何复选框。完成的任务写进 `completed[]`（带 `taskId`），由主 agent 统一标记；
- **`openspec/` 下全部产出物（proposal / specs / design / tasks）一律只读**——不只是任务文件。要改产出物 ⇒ 记进 `issues`（`kind: design-issue`）。让实现去改 design.md，就是让它改自己的验收标准；
- **禁止任何改写 git 状态的命令**（`commit` / `add` / `stash` / `checkout` / `reset` / `branch` / 全仓 format）——只改文件；
- 遇到模糊需求 / 设计问题 / 报错 / 越界 ⇒ **不要猜测**，记进 `issues` 并停下该条任务；
- **最终返回只输出一个 JSON 对象**（在 ```json 代码块里），严格遵循「Subagent 返回契约」，不夹杂散文。

### 6. 一波返回后：四道机械校验 → review → 标记

**四道校验，证据源都不是 subagent 的自述。任何一条不过 ⇒ 该组不得标记，按步骤 8 暂停。**

**① 地面真相**

```bash
git rev-parse HEAD                      # 与本波基线不同 ⇒ 有人动了 git ⇒ 围栏被破 ⇒ 硬失败，暂停
git status --porcelain -uall            # -uall 是必须的
```

`ground` = 这次的输出 **减去本波基线的脏文件集**。

`-uall` 不能省：不带它，新文件只吐一个目录（`?? backend/`）——而「新增一个 Controller / 一个组件」正是特性变更最常见的写入形式。减基线也不能省：否则用户手头任何未提交的活都会把诚实的运行判红。

**② 双向对账**（必须对称）

- `ground ∖ ⋃filesChanged` 非空 ⇒ **有未申报的改动**。
- **`⋃filesChanged ∖ ground` 非空 ⇒ 声称改了、实际没改。** 少了这一向，一次 `git stash` 就能让 `ground` 变空、所有校验全绿、整波工作蒸发而全部任务被标成完成。
- **`completed` 非空而 `filesChanged` 为空 ⇒ 直接判负。** 一个什么都不做、声称全做了的 subagent 否则会一路绿灯走到「准备归档」。

**③ 归因 —— 而归因只有隔离能给**

**并行的前提是隔离，不是写集。** 在一棵共享的树上，`git` 证明的是「最终哪些文件被改了」，**不是「谁改的」**——所以：

- **有 per-worker 隔离**（每组一个独立 git worktree）⇒ **每组的地面真相是它自己那棵树的 diff**，天然可归因。主 agent review 通过后**逐组串行合并回主树**，合并冲突就是碰撞，当场可见、可回滚。这是唯一严密的并行方式。
- **没有隔离** ⇒ **不并行**。一组一波，串行跑：那一波的 `ground` 里只有一个写者，归因是平凡的。

**写集只是规划辅助**（别把两个组放到同一批文件上），**不是执法机制**——它办不到：A 组的写集里有 `shared.ts`，B 组闯进去改了它、且不上报 ⇒ 那条路径仍然「落在恰好一个组的写集里」⇒ 检查全绿 ⇒ **B 覆盖掉的 A 的工作，无人知晓。** 写集能判定「这个文件该归谁」，**永远判定不了「除了他还有谁碰过」**。

**④ 任务覆盖率**

- `{completed} ∪ {incomplete}` 必须**恰好等于**派给该组的任务集（缺项 ⇒ 视为 `incomplete`，reason: "subagent 未回报"）。否则一个返回 `completed:[], incomplete:[], issues:[]` 的组会「无需关注」地通过，标 0 个复选框，**派给它的任务人间蒸发而无一处报错**。
- `needsAttention` **由主 agent 按 `incomplete`/`issues` 是否非空自己重算**，不信任返回里那个布尔值（畸形返回：`issues` 非空却自报 `false`）。

**四道过后，主 agent 亲自 review**：读 `ground` 里的**真实 diff**（不是 `filesChanged` 导航到的那些文件），对照 `completed` 的任务、上下文文件里的规格、现有契约与测试，判断是否真正满足、有无遗漏、有无越界。

- **通过** ⇒ 标记复选框。**定位链是：`completed[].taskId` → CLI 的 `tasks[id].description` → 文件里含该文本的那一行。**
  `description` 是 **CLI 自己从 tasks.md 解析出来的行文本**（例：`id=2` ⇒ `"1.2 补充单元测试"`），所以它就是文件里那一行——**不要拿 subagent 返回里的 `task` 去定位**，那是被审查方转述的文本，一个标点漂移就静默标错行，而唯一的下游检查只数**个数**，标错的那一行照样计数。subagent 的 `task` 只作二次确认：与 CLI 的 `description` 不符 ⇒ 按 review 不通过处理。
- **不通过** ⇒ 派修复 subagent（明确 spec：问题所在文件、具体问题、期望结果、验收方式）。**最多 2 轮**；仍不通过 ⇒ 按步骤 8 暂停，该组任务留在 `- [ ]`，输出里列出未通过的具体判据。（「重新 review 直到通过」是个无界循环——而 LLM 面对无界循环的收敛方式，就是第 3 轮把它判成通过。）
- **重算 `needsAttention: true` 的组不是整组作废**：先 review 并标记它 `completed[]` 里**已验收通过**的那部分，再就 `incomplete`/`issues` 暂停问人。否则一个诚实汇报「5 条做完 4 条」的 subagent，它做完的 4 条代码已落盘、复选框却仍是 `- [ ]`，下次会话会把它们当待办重新派发，第二个 subagent 在已改过的代码上重做一遍。

标记完 ⇒ **解锁依赖这一波的下游组**，回到步骤 5。

### 7. 集成门 —— 全流程唯一一道会真正失败的确定性门

所有组 review 通过后，在合并后的树上：

```bash
openspec-cn validate "<name>" --strict     # 只校验规格 markdown
<仓库的 build / test 命令>                  # 唯一能证明代码可用的那一半
```

**`validate --strict` 校验的是规格，不是代码**——而 `openspec/` 对 subagent 只读，本次会话没人碰过它们，它进来时就是 valid 的。**所以证明代码可用的只有 build/test 这一半。**

**build/test 命令的探测顺序**（可以多于一条——Java+React 就需要两条）：`package.json` 的 scripts → `Makefile` → `pom.xml` / `build.gradle` → `Cargo.toml` → CI 配置。一条都探不到 ⇒ 问用户要。**用户答「没有」⇒ 仍可完成，但 token 降级**：输出里打「**完成（无执行性证据）**」，且**不建议归档**——由用户自己决定。死胡同不是诚实，是把一个常见情况（纯文档 / 纯配置变更）变成永远无法收工。

**任一失败 ⇒**

1. **把受影响组的复选框改回 `- [ ]`**。否则任务文件仍然全是 `[x]`，下次会话 `instructions apply` 报 `all_done`，步骤 2 就会**归档一棵不能 build 的树**；
2. 不得宣布完成、不得建议归档；
3. 派修复 subagent（最多 2 轮）或按步骤 8 暂停。

这道门补的不是「某一组做错了」——那是 review 的事——而是**每组单独看都对、合起来不 build**：A 组改了接口签名、B 组按旧签名调用，两个 subagent 各自的上下文里都自洽。

### 8. 完成或暂停时，显示状态

重跑 `openspec-cn instructions apply --change "<name>" --json` 核对进度，然后按下方模板输出。**「建议归档」只在集成门通过后才说。**

## Subagent 返回契约

每个实现 / 修复 subagent 的最终返回必须是**唯一一个** JSON 对象（在 ```json 代码块里），无前后散文：

```json
{
  "group": "组名（范围）",
  "schema": "回显本次 Schema 名，确认读对了上下文",
  "completed":  [ { "taskId": "2", "task": "任务原文（逐字，仅作二次确认）" } ],
  "incomplete": [ { "taskId": "5", "task": "任务原文（逐字）", "reason": "未完成原因" } ],
  "filesChanged": [ { "path": "绝对路径", "summary": "改动要点" } ],
  "issues": [ { "kind": "ambiguous-requirement | design-issue | error | out-of-scope | blocker",
                "detail": "具体描述", "relatedTaskId": "3 或 null" } ],
  "needsAttention": false
}
```

- **`taskId` 取自 `instructions apply --json` 的 `id` 字段（序号 `"1"`、`"2"`…），不是 tasks.md 的章节号 `1.2`。** 它是主 agent 定位复选框的**唯一键**；`task` 逐字引用只作二次确认——`taskId` 对得上而文本对不上 ⇒ 按 review 不通过处理。
- `completed` ∪ `incomplete` 必须**恰好等于**派给该组的任务集（校验 ④）。
- `filesChanged` **只是导航，不是证据**——地面真相来自主 agent 自己跑的 `git status`（校验 ①②③）。
- `needsAttention` 为 `true` **当且仅当** `incomplete` 或 `issues` 非空。**主 agent 不信任这个字段，自己重算。**
- 主 agent 把这份 schema 原样贴给 subagent，不让它自行约定返回格式。

## 实现专家与解析梯

按组的范围选专家（逻辑角色来自 [agency-agents](https://github.com/msitarzewski/agency-agents)）：

| 实现分组 | 逻辑角色 | agency-agents 源路径 |
|---|---|---|
| 前端 | `Frontend Developer` | `engineering/engineering-frontend-developer.md` |
| 后端 / API | `Backend Architect` | `engineering/engineering-backend-architect.md` |
| 数据 / 数据库 | `Data Engineer`（schema、迁移、管道）/ `Database Optimizer`（查询计划、索引） | `engineering/engineering-data-engineer.md` / `engineering/engineering-database-optimizer.md` |
| 基础设施 | `DevOps Automator` | `engineering/engineering-devops-automator.md` |
| 通用小修 / 无匹配行 | `Minimal Change Engineer` | `engineering/engineering-minimal-change-engineer.md` |

**两者都涉及时拆成两个组**——各有不相交的写集、显式声明依赖（通常 Optimizer 依赖 Engineer 的 schema 先落地），走正常波次。**绝不在同一组里并派两个 subagent**：那是在同一批 schema/迁移/查询文件上自造竞态，而且两份 JSON 的 `group` 是同一个标量，`completed[]` 会重叠。

**无匹配行的组**（测试 / 文档 / 移动端 / 安全…）⇒ 用 `Minimal Change Engineer`，并在输出里标注 `(fallback)`。

**catalog 是用户装的前置条件（见 README）；本 skill 及其派出的 subagent 只读它、不写它**——写实现代码的 subagent，来自用户自己 clone、自己控制版本的那份 checkout。缺了就降级并说明，本 skill 不替用户装。

**三层解析（回显解析到的层级）：**

1. **registered** —— 该角色已注册为宿主的原生 subagent（按其 frontmatter `name:`，如 `Frontend Developer`）→ 直接派发。**注意：catalog 文件的 frontmatter `name:` 是显示名（`Frontend Developer`），不是文件名 slug（`engineering-frontend-developer`）——按错的那个查，三层全都命中不了。**
2. **local** —— 上表的源路径，在 `~/.agency-agents/`（一个 catalog 的 git clone，嵌套两层）下取；校验 frontmatter `name:` 等于该角色名；正文（跳过 frontmatter）作 persona 注入 `general-purpose`。**回显带上解析到的路径**——`<组>/<角色>：[local: <源路径>]`——让层级成为可被证伪的声明。
3. **embedded** —— catalog 未安装 · 该角色的源路径不在其中 · `name:` 校验不相等 ⇒ 内嵌浓缩 prompt（**更弱的专家**）。**层级回显必须带上原因**——静默降级会让用户以为派的是真专家：`<组>/<角色>：[embedded: agency-agents 未安装]` · `<组>/<角色>：[embedded: <角色> 在 <源路径> 解析不出]`。只报事实、不给命令——装不装、怎么装 catalog 是用户的事（见 README）。前端「你是前端开发者。用现代 Web 技术实现该任务，遵循代码库现有模式，兼顾可访问性与响应式设计。」后端「你是后端架构师。按现有 API 模式、错误处理约定和数据模型实现该任务，保证向后兼容。」数据「你是数据工程师。按现有 schema 约定、迁移模式和查询优化实践实现该任务。」基础设施「你是 DevOps 自动化工程师。按现有 IaC 模式、CI/CD 约定和部署实践实现该任务。」通用小修「你是最小修改工程师。只用最小可能的 diff 实现指定任务；除非任务明确要求，不加抽象、配置、依赖或特性；不碰无关代码。」
   **`embedded` 层的组，review 时逐文件读完整 diff，不得抽查。**

## 输出模板

**分组方案（步骤 4 后）**

```
## 任务分组：<change-name>（Schema：<schema-name>）

待处理任务 M 个，按范围分为 K 组：

- **组 A — 后端**（3 个任务：1, 2, 5）· 专家：Backend Architect [registered] · 写集：`backend/`, `api/`
- **组 B — 前端**（2 个任务：3, 4）· 专家：Frontend Developer [local: engineering/engineering-frontend-developer.md] · 写集：`frontend/`
- **组 C — 测试**（2 个任务：6, 7）· 专家：Minimal Change Engineer [embedded] (fallback) · 写集：`tests/`

写集两两不相交 ✓  依赖：A → C（测试依赖后端就位）；B 独立
波次 1：组 A、组 B 并行   波次 2：组 C
```

**派发与实现期间**

```
## 正在实现：<change-name>（Schema：<schema-name>）

▶ 波次 1 · 基线：HEAD=a1b2c3d · 脏文件 0
▶ 波次 1 · 并行派发：组 A、组 B
  ✓ 组 A 返回 · ✓ 组 B 返回
▶ 波次 1 · 校验：地面真相 ✓ · 双向对账 ✓ · 写集归因 ✓ · 覆盖率 ✓
▶ 波次 1 · Review 通过 → 标记任务 1,2,5 / 3,4 → 解锁组 C
▶ 波次 2 · 基线：HEAD=a1b2c3d · 脏文件 5（= 波次 1 的产出）
▶ 波次 2 · 派发组 C → 返回 → 校验 ✓ → Review 通过 → 标记任务 6,7
▶ 集成门：openspec-cn validate --strict ✓ · pnpm test ✓ · mvn -q test ✓
```

**完成时**

```
## 实现完成

**变更：** <change-name>　**Schema：** <schema-name>　**进度：** 7/7 ✓

### 本次会话已完成（按组）
- 组 A：[x] 1、[x] 2、[x] 5　　- 组 B：[x] 3、[x] 4　　- 组 C：[x] 6、[x] 7

### 集成门
openspec-cn validate --strict ✓ · pnpm test ✓ · mvn -q test ✓

所有任务已完成，且集成门通过。可以归档此变更。
```

**暂停时**

```
## 实现暂停

**变更：** <change-name>　**进度：** 4/7

### 卡在哪
<校验哪一条不过 / review 未通过的具体判据 / subagent 报的 issue>

### 已经落地并标记的
- 组 A：[x] 1、[x] 2　（这部分已 review 通过，不会重做）

**选项：** 1. <…>　2. <…>　3. 其他方法

您想怎么做？
```

## Claude Code 机制

- 并行派发：**在同一条消息里发出多个 `Agent` 调用**；写集不相交且依赖就绪的组才进同一波。
- 并行组加 `isolation: "worktree"`——它把「写集归因」从启发式变成机制。
- 实现 subagent 用 `general-purpose`（它需要 Write / Edit / Bash）。

## 护栏（这一段是压缩的契约，不是第二份规则——每条都指回它的步骤）

- **主 agent 不写实现代码，但运行命令**：git / build / test 是它的证据来源，不是违规（证据规则）。
- **`filesChanged` 只是导航。** 地面真相是主 agent 自己跑的**树快照 diff**（`git write-tree`，波首取 `BASE`、波尾再取一次），不是基线相减；对账必须**双向**（步骤 6 ①②）。
- **并行的前提是隔离，不是写集**（步骤 6 ③）。**写集只是规划辅助**——它判定得了「这个文件该归谁」，永远判定不了「除了他还有谁碰过」。共享树上并行 ⇒ 无碰撞证据源 ⇒ **要么每组一个 worktree，要么串行**。
- **基线每波重记**（步骤 5）。只记一次的话，第二波诚实的运行必被判越界。
- **复选框只由主 agent 写，按 `taskId`（CLI 的 `id` 序号）标记**（步骤 6）。
- **subagent 禁止改写 git 状态；`openspec/` 全部产出物对它只读**（步骤 5）。
- **每波返回就 review 这一波，通过才标记、才解锁下游**——不是等全部派发完再统一 review（步骤 5）。修复最多 2 轮。
- **收尾必过集成门；门挂了要把复选框改回 `- [ ]`；`all_done` 不得单独信任**（步骤 2、7）。
- 模棱两可 / 设计问题 / 报错 / 越界 ⇒ **不要猜测**，记 `issues` 并停下该条任务。
- 用 CLI 输出里的 `contextFiles`，不要假设文件名。

## 流畅的工作流集成

支持「变更上的操作」模型：**可以随时调用**（产出物完成前、部分实现之后、与其他操作交错）；**允许产出物更新**——某个 subagent 的返回揭示了设计问题 ⇒ 主 agent 暂停并建议更新产出物（由主 agent 改，subagent 只读），不是阶段锁定的。
