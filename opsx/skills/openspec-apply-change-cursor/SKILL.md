---
name: openspec-apply-change-cursor
description: 以编排模式实现 OpenSpec 变更——主 agent 按范围分组，每组派 cursor-agent（默认模型 composer-2.5）当编码 worker，主 agent 只做状态管理；全部编码完成后挂一次 review-loop 对抗 review。当用户想用 cursor 当 worker 的分组方式开始/继续实现任务时使用。这是 openspec-apply-change 的 cursor-worker 并存定制版，不覆盖原版，也不覆盖 subagent 版。
license: MIT
compatibility: 需要 openspec-cn CLI、cursor-agent CLI（已登录）、以及已安装的 sub-agents-skills（runner@sub-agents-skills）提供 run_subagent.py。
metadata:
  author: openspec
  version: "1.0-cursor"
  basedOn: "openspec-apply-change-subagent (2.0-custom)"
  worker: "cursor-agent (composer-2.5, safe-edit) via sub-agents-skills/run_subagent.py"
  customization: "worker 从 Claude subagent 换成 cursor-agent（shell-out run_subagent.py）；新增 doctor 前置；收尾改为挂一次 review-loop。作为独立 skill 并存，不覆盖原版与 subagent 版。"
---

实现 OpenSpec 变更中的任务。**用 cursor-agent 当编码 worker。**

**角色模型（本定制版的核心）**

主 agent 是**编排者（orchestrator）**，不亲自写实现代码：

- **主 agent 负责**：跑 doctor 前置、选变更、跑 `openspec-cn` 状态/指令、读上下文文件、把任务按范围分组、**派发 cursor-agent worker**、解析 worker 返回、补标遗漏复选框、收尾挂一次 review-loop、报告进度、建议归档。
- **cursor-agent worker 负责**：每组任务的具体编码实现（经 `sub-agents-skills` 的 `run_subagent.py` 以 `--print --output-format json --trust` 单次调用、默认模型 composer-2.5），完成后自行把任务文件中的复选框标记为 `- [x]`，并在输出末尾给出契约 JSON。
- 主 agent 只在做极小的状态/标记修正时才直接动文件；任何成规模的编码都必须下放给 cursor worker。

**与 subagent 版的差异**：worker 由 `Task(general-purpose)` 换成 shell-out cursor-agent（走 cursor 订阅额度而非 Claude token）；review 不再每组/分项目做，而是**全部编码完成后挂一次 review-loop**。其余编排逻辑一致。

**输入**：可选指定变更名称。如果省略，检查是否可以从对话上下文中推断。如果模糊或不明确，你**必须**提示获取可用变更。

---

**步骤 0：doctor 前置（每次开跑前必做，不可跳过）**

把环境前置检查显式化；任一不满足就**明确报错 + 给修复指令并停止**，不要默默退化或改用 Claude subagent。

```bash
# A) cursor-agent 在 PATH
command -v cursor-agent >/dev/null || { echo "✗ 缺 cursor-agent。装：curl https://cursor.com/install -fsS | bash"; exit 1; }
# B) cursor-agent 已登录
cursor-agent status 2>&1 | grep -qi "Logged in" || { echo "✗ cursor-agent 未登录。跑：cursor-agent login"; exit 1; }
# C) 定位 sub-agents-skills 的 run_subagent.py（marketplace 路径不带版本号，最稳；回退到 cache 最新版）
RS="$HOME/.claude/plugins/marketplaces/sub-agents-skills/skills/sub-agents/scripts/run_subagent.py"
[ -f "$RS" ] || RS=$(ls -t "$HOME"/.claude/plugins/cache/sub-agents-skills/runner/*/skills/sub-agents/scripts/run_subagent.py 2>/dev/null | head -1)
[ -n "$RS" ] && [ -f "$RS" ] || { echo "✗ 缺 sub-agents-skills。装：/plugin marketplace add shinpr/sub-agents-skills 然后 /plugin install runner@sub-agents-skills"; exit 1; }
# D) 默认模型应为 composer-2.5（提示性，不强阻塞）
cursor-agent models 2>&1 | grep -i "composer-2.5" | grep -qi current || echo "⚠ cursor 默认模型非 composer-2.5；本 skill 依赖默认模型，请确认或在 cursor 设置中切回 composer-2.5"
# E) 不以 root 运行（cursor --trust/headless 会写文件与跑 shell）
[ "$(id -u)" -ne 0 ] || { echo "✗ 不要以 root 运行 worker（会制造 root-owned 文件）"; exit 1; }
echo "✓ doctor 通过；RS=$RS"
```

**确保 worker 的 agent 定义就位**（不污染用户仓）：worker 定义放在固定位置 `~/.opsx-cursor/agents/opsx-implementer.md`，调用时用 `--agents-dir` 指过去。若该文件不存在，主 agent 用 Write 工具按下方**「worker agent 定义」**原文创建它（内容固定，不要逐次改写）。

主 agent 把 doctor 结果用一行汇报（通过 / 缺哪一项 + 修复指令）。doctor 不通过则停在这里。

---

**步骤 1：选择变更**

如果提供了名称，使用它。否则：
- 如果用户提到了某个变更，从对话上下文中推断
- 如果只存在一个活动变更，自动选择
- 如果不明确，运行 `openspec-cn list --json` 获取可用变更，并使用 **AskUserQuestion tool** 让用户选择

始终宣布："正在使用变更：<name>"以及如何覆盖（例如，`/opsx:apply-cursor <other>`）。

**步骤 2：检查状态以了解 Schema**
```bash
openspec-cn status --change "<name>" --json
```
解析 JSON 了解：`schemaName`（工作流 Schema，如 "spec-driven"）；哪个产出物包含任务（spec-driven 通常是 "tasks"）。

**步骤 3：获取应用指令**
```bash
openspec-cn instructions apply --change "<name>" --json
```
返回 `contextFiles`（产出物 ID → 文件路径数组）、进度、带状态的任务列表、动态指令。
- `state: "blocked"`（缺产出物）：显示消息，建议 `openspec-continue-change`
- `state: "all_done"`：祝贺，建议归档
- 否则：继续

**步骤 4：阅读上下文文件**

主 agent 必须亲自阅读 apply instructions 输出中 `contextFiles` 列出的每个文件路径——这是后续分组、写 worker spec、收尾 review 的依据。文件取决于 Schema（spec-driven：proposal, specs, design, tasks；其他模式遵循 CLI 输出的 contextFiles）。

**步骤 5：按范围对待处理任务分组**

分析所有 `state` 不为完成的任务，按**范围**分组：

- **范围 = 任务所触及的子项目 / 模块 / 技术栈**。典型边界：Java 端 / Rust 端 / React 端；backend / frontend / infra；或不同 capability / spec 区域。
- 每个任务归入它主要改动的那个范围；跨范围任务归入"主战场"，并在 worker spec 里点明需兼顾的另一侧。
- 组的粒度以 **3–8 个任务**为宜：太碎合并，过大再拆。worker 单次有超时上限（`--timeout`，默认 10 分钟），过大的组宁可拆小。
- **判断组间依赖**：若 B 组依赖 A 组产出（前端调后端本次新增 API、测试依赖被测代码先就位），记 A → B。无此关系的组互相独立。
- 把分组结果与依赖关系展示给用户（见"分组方案输出"），然后继续。

**按适配性细化下放**：分组后，对每组判断是否下放给 cursor worker：

- **下放**：纯代码、机械、规格已明确的任务（如 manifest/测试编写、按既定模式转写、跨文件结构同步）。
- **留主 agent**：需要复杂推理或迭代探索的任务（如 fixture 录制、阈值调参），以及所有验证（见步骤 7）。
- **复杂单任务**（推理负载大）有超时风险，降险二选一：(a) 拆成更小的子组；(b) 主 agent 先把目标文件预填到只需「转写/补全」的程度再下放。

若全部待处理任务本就同一范围且无法有意义切分，则视为**单组**，直接进入下一步（仍走 cursor 派发）。

**步骤 6：派发 cursor-agent worker 实现（先并行后串行）**

按拓扑顺序派发。**worker 派发用 Bash 工具 shell-out `run_subagent.py`，不是 Agent tool。**

dispatch 命令模板（`$RS` 取 doctor 里定位到的路径）：

```bash
python3 "$RS" \
  --agent opsx-implementer \
  --agents-dir "$HOME/.opsx-cursor/agents" \
  --cwd "<目标仓的绝对路径>" \
  --timeout 600000 \
  --prompt "<下方约定的完整组 spec>"
```

- **并行**：当前所有前置依赖已满足的组，在**同一条消息里发出多个 Bash 调用**、每个 `run_in_background: true`，并发执行；随后收集各自后台输出。
- **串行**：有依赖的组等其前置组的 worker 全部返回后，再发下一批。
- 重复直到所有组都已派发完。

每个组的 **`--prompt`（组 spec）必须**包含（主 agent 全权写清楚，不让 worker 揣测范围）：
- 变更名称与 Schema
- 该组负责的**完整任务清单**（逐条列出任务原文）
- 相关上下文文件的**绝对路径**（proposal / specs / design / tasks 等），要求 worker 自己读
- 任务文件（tasks.md）的绝对路径，并明确约定：**每完成一个任务，立即把该任务的 `- [ ]` 改为 `- [x]`**
- 约束：保持改动最小且**限定在本组范围内**；**不要碰其他组负责的任务或其复选框**；**不要执行 `git commit` / `git add` / 任何 git 写操作**；遇到不清楚的需求或设计问题不要猜测，停下来在契约 JSON 的 `issues` 里说明
- **不必自跑验证命令**：worker 只需实现代码 + 标复选框 + 报告契约，验证由主 agent 统一做（步骤 7）。若因环境限制跑不了 pytest/load/lint，不要空转、也不要因此判失败，在 `issues` 里用 `kind: blocker` 注明「环境受限无法验证」即可。
- **在最终输出的末尾，附上一个符合下方「worker 返回契约」schema 的 JSON 对象（放进 ```json 代码块）**——主 agent 靠它判断进度与是否暂停

**步骤 7：解析 worker 返回 → 暂停检查 → 收尾挂一次 review-loop**

7a. **解析双层返回。** `run_subagent.py` 的外层输出是一行 JSON：
```json
{"result": "...cursor 的全部输出...", "exit_code": 0, "status": "success", "cli": "cursor-agent"}
```
先看外层 `status`：
- `success`（exit_code ∈ {0, 143}）：正常，进入内层解析。
- `partial`（exit_code 124 = 超时）：该组超时但有部分产出，按"该组 incomplete"处理 → 暂停或拆小重发。
- `error`：worker 失败，读 `error` 字段，按暂停流程摊给用户。

再从外层 `result` 文本里提取 worker 输出的**内层契约 JSON**（```json 块）。若 worker 没输出契约 JSON，降级用 `result` 文本 + `git -C <repo> diff --stat` 兜底判断本组实际改了什么（记一笔"worker 未返回契约，已用 diff 兜底"）。

7b. **暂停检查（区分真问题 vs 环境限制）。** worker 报 `needsAttention: true` 不一定是真问题，按下面分流：

- **仅环境限制**（`issues` 全是「验证命令被拒 / 无法跑 pytest/load」这类，无 `incomplete`、无代码缺陷，外层 `status` 为 `success`）：不暂停。视该组已交付，验证接到主 agent（自己跑 pytest/load/lint 确认），过即视同通过。
- **真问题**（`issues` 含 `ambiguous-requirement / design-issue / error`，或有 `incomplete`，或外层 `status` 为 `partial`/`error`）：不进入 review，按步骤 8 暂停；超时（partial/exit 124）按步骤 7a 拆小或预填后重发，不原样重试。

7c. **补标复选框。** 对各组 `completed[].checkboxMarked` 为 `false` 的任务，主 agent 在 tasks.md 补标 `- [x]` 并记一笔。

7d. **收尾挂一次 review-loop（本版的 review 方式）。** 全部组都返回且无暂停项后，对**本次整体编码变更**挂**一次** review-loop：调用 `review-loop` skill，review 范围 = 本变更的提案/规格（contextFiles）+ 全部组的代码 diff，目标是"编码是否正确、是否符合提案要求"。

- review-loop 放行（APPROVE / CLEAR / APPROVE-DEGRADED）：进入步骤 8 报完成。
- review-loop 不通过：由 review-loop 自身的修复循环处理（默认派 Minimal Change Engineer 修复后重新 review），直至放行或到其轮数上限。若 review-loop 反复指向同一组的实现缺陷，主 agent 可改为把该组的修复 spec 重新下放给 cursor worker（同步骤 6 的 dispatch），再回到 7a。

**步骤 8：完成或暂停时，显示状态**

再次运行 `openspec-cn instructions apply --change "<name>" --json` 核对进度，然后显示：本次会话完成的任务；总体进度 "N/M 任务已完成"；全部完成则建议归档；暂停则解释原因并等待指导。

---

**worker 返回契约**

cursor worker 的输出末尾必须附**一个** JSON 对象（包在 ```json 代码块里），schema 如下（与 subagent 版一致，便于主 agent 统一解析）：

```json
{
  "group": "组名（范围）",
  "schema": "回显本次 Schema 名（如 spec-driven），确认 worker 读对了上下文",
  "completed": [
    { "task": "任务文件中的原文（逐字引用）", "checkboxMarked": true }
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
- 这个契约 JSON 由 worker 写在 cursor 输出文本里，**外面还套着 `run_subagent.py` 的一层** `{result, status, exit_code, cli}`；主 agent 先剥外层取 `result`，再从 `result` 提取内层契约。
- `needsAttention` 为 `true` **当且仅当** `incomplete` 或 `issues` 非空。主 agent 见 `true`、或外层 `status` 为 `partial`/`error`，必须按步骤 8 暂停，不得直接进 review。
- `completed[].task` 逐字引用任务原文，便于比对复选框；`checkboxMarked` 由 worker 自报，`false` 时主 agent 补标并记一笔。
- worker 遇模糊需求 / 设计问题 / 报错 / 越界时**不要猜测**——记进 `issues` 并停下该条任务。
- 主 agent 在组 spec 里把这份 schema 原样贴给 worker，不让其自行约定格式。

---

**worker agent 定义**（doctor 阶段确保写到 `~/.opsx-cursor/agents/opsx-implementer.md`，内容固定）

```markdown
---
run-agent: cursor-agent
permission: safe-edit
---

# OpSx Implementer

Implement the assigned group of OpenSpec tasks directly in the workspace.

## Task
- Read every context file path given in the prompt (proposal / specs / design / tasks) before coding.
- Implement exactly the tasks listed for THIS group. Keep changes minimal and scoped.
- After completing each task, immediately flip its checkbox in tasks.md from `- [ ]` to `- [x]`.

## Out of Scope / Prohibited
- Do NOT touch tasks or checkboxes owned by other groups.
- Do NOT run any git write command (`git add`, `git commit`, etc.).
- Do NOT guess on ambiguous requirements or design problems — record them in the issues array and stop that task.

## Done When
- All in-scope tasks are implemented in real files and their checkboxes are flipped.
- The final output ends with a single JSON object (in a ```json block) matching the contract schema the prompt specifies.
```

---

**分组方案输出（步骤 5 后）**

```
## 任务分组：<change-name>（Schema：<schema-name>） · worker：cursor-agent / composer-2.5

待处理任务 M 个，按范围分为 K 组：

- **组 A — <范围名>**（N 个任务）：任务 1, 2, 5
- **组 B — <范围名>**（N 个任务）：任务 3, 4
- **组 C — <范围名>**（N 个任务）：任务 6, 7

依赖：组 A、组 B 独立 → 并行；组 C 依赖组 A → 待组 A 完成后执行。
```

**派发与实现期间的输出**

```
## 正在实现：<change-name>（Schema：<schema-name>） · worker：cursor-agent

✓ doctor 通过
▶ 并行派发 cursor worker：组 A、组 B
  ✓ 组 A 返回（status=success）：完成任务 1, 2, 5
  ✓ 组 B 返回（status=success）：完成任务 3, 4
▶ 串行派发：组 C（依赖组 A）
  ✓ 组 C 返回（status=success）：完成任务 6, 7

▶ 收尾 review-loop（提案 + 全部代码 diff）
  ✓ 放行：APPROVE
```

**完成时的输出**

```
## 实现完成

**变更：** <change-name>
**Schema：** <schema-name>
**worker：** cursor-agent / composer-2.5
**进度：** 7/7 任务已完成 ✓

### 本次会话已完成（按组）
- 组 A：[x] 任务 1、[x] 任务 2、[x] 任务 5
- 组 B：[x] 任务 3、[x] 任务 4
- 组 C：[x] 任务 6、[x] 任务 7

### Review 结论
<review-loop 放行结论 / APPROVE-DEGRADED 说明>

所有任务已完成！准备归档此变更。
```

**暂停时的输出（遇到问题）**

```
## 实现暂停

**变更：** <change-name>
**Schema：** <schema-name>
**进度：** 4/7 任务已完成

### 遇到的问题
<来自某组 worker 的 issues / incomplete / 超时，或 review-loop 反复未通过的问题>

**选项：**
1. <选项 1>
2. <选项 2>
3. 其他方法

您想怎么做？
```

---

**护栏**
- 开跑前必跑 **doctor**（步骤 0）；任一前置不满足就报错 + 修复指令并停止，**不默默退化、不回退到 Claude subagent**
- 主 agent 不亲自写实现代码——所有成规模的编码都派 cursor worker；主 agent 只做编排、状态管理与收尾 review
- 开始前主 agent 始终亲自阅读上下文文件（来自 apply instructions 输出）
- 分组依据是"范围"（子项目 / 模块 / 技术栈），不是任务序号；先并行后串行，依赖关系由主 agent 判断；组粒度 3–8 任务，过大易超时要拆小
- worker 派发用 shell-out `run_subagent.py`（`--agent opsx-implementer --agents-dir ~/.opsx-cursor/agents --cwd <repo>`），并行用 Bash `run_in_background`；把完整任务清单、上下文文件绝对路径、约束、契约 schema 一次性写进 `--prompt`
- worker 返回是双层 JSON（外层 run_subagent + 内层契约）；主 agent 先剥外层看 `status`（partial/error 即暂停），再解析内层 `needsAttention`——但**区分真问题与环境限制**：worker 因沙箱跑不了验证而报 `needsAttention` 不算真问题，主 agent 自己验、不暂停；只有实质缺陷 / `incomplete` / 超时 / error 才暂停
- 复选框 `- [x]` 由 cursor worker 自己标记（在契约 `checkboxMarked` 中自报）；主 agent 仅在漏标时补标
- review 方式：**全部编码完成后挂一次 review-loop**（提案 + 全部代码 diff），不通过由 review-loop 自身修复循环处理；必要时把某组修复 spec 重新下放给 cursor worker
- worker spec 里禁止 worker 跑 git 写操作；主 agent 也不替 worker 提交
- 任务模棱两可、揭示设计问题、worker 报错/超时/越界时暂停——不要猜测
- 使用 CLI 输出中的 contextFiles，不要假设特定文件名
- 按适配性下放：纯代码 / 机械 / 规格明确的任务下放 cursor；复杂推理 / 迭代 / 调参留主 agent；复杂单任务有超时风险，拆小或预填到「转写」程度再下放
- 所有验证归主 agent：worker spec 明说「不必自验」；收尾 review-loop 前主 agent 先自己跑验证确认各组产出，再进对抗 review

**流畅的工作流集成**

支持"变更上的操作"模型：可随时调用（产出物未全完成时、部分实现后、与其他操作交错）；若某组 worker 返回揭示设计问题，主 agent 暂停并建议更新产出物——不是阶段锁定的。
