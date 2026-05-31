---
name: review-loop
description: 对本次提案与代码变更跑对抗性 review 自动循环——每轮三方并行 Codex（codex:codex-rescue）+ Code Reviewer + Reality Checker，合并去重问题后 triage，默认派 Minimal Change Engineer 修复，再重新 review，循环到放行（APPROVE/CLEAR；Codex 结构性未跑完时 APPROVE-DEGRADED）或到轮数上限（可配置安全兜底，默认 10，/goal 下可不设）。用户说「对本次提案/变更做对抗性 review 循环」「用 Codex 对本次变更 review 循环」「review 到通过为止」时触发；常配合内置命令 /goal。
---

# review-loop

对「本次提案 + 本次代码变更」做对抗性 review 并自动迭代到通过。每轮：派 reviewer → triage → 派修复 → 重新 review，直到放行或撞上限。直接 `/review-loop` 调用；长跑用 `/goal` 包住（见末节）。

## 结论口径

子代理常不照规范（写错 token、级别拍脑袋、不给结论行）。**主 agent 收到结论后按本节自行归一，不被子代理写的 token 带跑。**

**严重级别**（每条问题必带其一）：

- **blocker** —— 发布即坏：错误结果 / 数据损坏 / 崩溃、安全漏洞、与依赖方契约或 schema 不兼容、核心场景不可用。必须修才放行。
- **major** —— 重要缺陷：设计缺陷、漏掉的失败模式或边界、与既有代码明显不一致、缺关键校验。默认修；确实不修须按下文「未解决」定义复核降级，不能级别不变只记理由。
- **minor** —— 不影响正确性的局部小问题。按成本收益修。
- **nit** —— 纯风格 / 措辞 / 格式。通常不修。

**结论 token**：放行 = `APPROVE`（Reality Checker 习惯写 `CLEAR`，等价）；打回 = `CHANGES-REQUESTED`（写成 `NEEDS WORK` 同义，按打回处理）。

**先复核级别**：子代理自填的级别常拍脑袋。主 agent 按上面定义对每条问题**重新定级**——既把被低标的 blocker/major 提上来（尤其子代理打回却把理由标成 minor/nit 时），也把被高标的压下去，不照搬子代理的级别、也不照搬其末尾 token。**下调只有在按定义重判确实落到更低档时才成立**；说不出哪条定义把原档判错、纯为了终止而降级，本身算未解决，不许。

**「未解决」的定义**：一条 blocker/major 只有在**已修复**、或**主 agent 复核后显式降级为 minor/nit 或判定不适用**时才算已解决；仅口头记个理由跳过、级别不变，仍算**未解决**。

**归一硬规则**：复核后，清单含未解决 blocker/major ⇒ 该结论按**打回**计（哪怕子代理写了 APPROVE）；只剩 minor/nit ⇒ 按**放行**计。**本 skill 全程的「放行 / 打回」都指这个归一后结论，不是子代理末尾 token。**

`APPROVE-DEGRADED`（降级放行）与 `CAPPED`（达上限未放行）都是**主 agent 专用的终止 token、非子代理 token、不入任何槽**——见终止条件。

## 循环

### 1. 派 reviewer

同一条消息并行派三方。每个 prompt 自包含：本次提案与变更、对照的真理源文件、前轮已修过什么（要找**新** ship-blocker）、并**原样给出上面的级别定义和"末尾恰好一行 `APPROVE` / `CHANGES-REQUESTED` + 问题清单（级别 / 位置 / 说明 / 改法）"格式要求**。

- **Codex** —— `subagent_type: codex:codex-rescue`，只读 review。这是循环唯一能自动派的 Codex 路径（`/codex:adversarial-review` 是 `disable-model-invocation` 的人工命令、且不吐结论行，循环不调它）。prompt 必须明确要它给结论行（Codex 默认只返回散文）。
- `subagent_type: "Code Reviewer"` —— correctness / 契约 / 边界 / 安全 / 与既有代码一致性。
- `subagent_type: "Reality Checker"` —— 逼出未证明的假设、漏掉的失败模式、不可测的验收、乐观放过的断言。

子代理未注册则回退 `subagent_type: general-purpose`（自写强对抗 prompt）。安全敏感面再加 `subagent_type: "Security Engineer"`。

> `Code Reviewer` / `Reality Checker` / `Security Engineer`（及步骤 3 的 `Minimal Change Engineer`）来自 agency-agents 合集：`github.com/msitarzewski/agency-agents`（`engineering/` 与 `testing/` 目录）；`subagent_type` 用各 agent frontmatter 的 `name`。本机缺失时从该 repo 安装，或先用 `general-purpose` 回退跑。

**每轮必回显一行三槽状态**（子代理失败会返回空，与"无问题"不可区分；空槽不许默认成放行）。槽位写**归一后结论**、不是子代理原 token（它写 APPROVE 但清单有未解决 blocker/major ⇒ 槽位写 CHANGES-REQUESTED）：

```
本轮 reviewer：Code Reviewer=APPROVE │ Reality Checker=CHANGES-REQUESTED │ Codex=未跑完(空返回)
```

Codex 槽只写 `APPROVE` / `CHANGES-REQUESTED` / `未跑完(原因)`；`APPROVE-DEGRADED` 只出现在最终聚合结论行，不入任何槽。

### 2. Triage

三方问题**合并去重成一份**（同一处别派两套改法），按「结论口径」**复核定级**，逐条判断：blocker/major 默认修；确实不修的 major 必须主 agent **复核降级**（按定义重判为 minor/nit 或判定不适用）再记理由——不能级别不变只口头跳过（按「未解决」定义它仍算未解决，循环不会终止）；minor/nit 按收益。向用户说明修哪些、跳哪些。无值得修的问题 → 终止条件。

### 3. 派修复

修复默认派子代理（干净上下文，不带主线设计的先入为主）。按类型选执行者：

- **默认** `subagent_type: "Minimal Change Engineer"`（最小 diff、拒绝 scope creep；未注册回退 `general-purpose`）——局部 bug、单模块、照 spec 的机械改动。
- **大型复杂**（跨模块 / 服务边界、需重推架构或数据流、schema/API 迁移、需设计测试策略）`subagent_type: codex:codex-rescue`。
- **OpenSpec 纯文档机械修复**（措辞 / 格式 / 补齐已定方案）主 agent 直接改；涉及需求语义或契约判断则按上两档分流。

**主 agent 负责写完整修复 spec**——每问题给文件路径、具体改法、验收方式。prompt 里交代边界：先做 spec 内无争议项；只有新发现会使 spec 出错 / 引入回归 / 需扩大范围时才暂停回报，其余相邻小问题只记不擅自扩。

### 4. 重新 review

回步骤 1 三方并行重试（Codex 可能中途恢复）。**但"每轮重试"只在循环将继续（仍有未解决 blocker/major）时适用**；若两个 Claude 专家本轮**归一后**均放行，进终止条件判干净 / 降级 / 继续。其中"不为再试一次 Codex 多跑一轮"只针对 Codex 已给结论或属结构性的情况；Codex 属**瞬态**未跑完时，按终止条件仍需下一轮重试。

## 终止条件

预期 reviewer 恒为三方；Codex 未出可解析结论一律算「未跑完」，不降格成「本轮不预期」。「未跑完」分两类，处理不同：

- **瞬态**（空返回 / 跑了但没给结论行）—— 下一轮用更严 prompt（"末尾只输出一行 verdict"）重试，**不早停**。Codex 跑了只是没吐结论行 ≠ 它否决，不可据此报 APPROVE-DEGRADED。
- **结构性**（未装 / 未登录 / 额度，本会话不会自行恢复）—— 重试无意义。
- **判不准属哪类**时按**瞬态**处理（重试；等后续轮出现明确信号——如"未登录"——再转结构性）。这样默认走安全侧：误判只多费几轮、不会假放行。

判定：

- **干净终止**：三方本轮都实际跑成（Codex 给了可解析结论）、**归一后均放行** → 以 `APPROVE` / `CLEAR` 结束。至少要两个 Claude 专家都返回了结论；某专家（非 Codex）未返回按未完成处理（重试或回退 `general-purpose` 补齐），不可仅凭单个专家放行就终止。任一打回即继续。
- **Codex 瞬态未跑完**：两专家归一后放行、但 Codex 只是**瞬态**未跑完（空返回 / 没给结论行）→ **不终止也不降级**，下一轮按瞬态规则重试 Codex，直到它给出结论（→ 干净终止）、转为结构性（→ 降级终止）、或撞轮数上限。
- **降级终止**：两个 Claude 专家**归一后**都放行，但 Codex 属**结构性**未跑完 → **立即停止**（不必跑满上限——重复审已被专家放过的代码不产生新信息），最终结论用 `APPROVE-DEGRADED` 并括注证据（如 `APPROVE-DEGRADED (Codex 未跑完: 未登录)`），不报成干净 APPROVE。
- **轮数上限**：一个**可配置的安全兜底**——防病态不收敛（修复反复引入新问题、两 reviewer 长期僵持），**不是"够好了就停"的质量门槛**。没有原则上的正确值；默认 **10 轮**，嫌不够直接调高（10–20 常见）。真正的终结是**收敛**（拿到放行 token）或你在 /goal 里写的完成条件，不是这个数。
  - **设了上限、到顶时必须终止**（守住"不无限循环"），按状态给终止 token：两专家已放行、仅 Codex **瞬态**未跑完 → `APPROVE-DEGRADED (…: 瞬态, 达上限)`；仍有未解决 blocker/major 或某 Claude 专家槽仍 `CHANGES-REQUESTED` / 空 / 未跑完 → `CAPPED (达上限, 剩 N 项未决)` 并列出未决项——**终止 token、明确不是放行**，不报干净 APPROVE。
  - **/goal 下可不设上限**（按 goal 自己的完成条件跑到放行为止，见末节）：此时 `CAPPED` 不触发，循环只在拿到放行 token 或你中断时结束——你自愿用"可能长跑"换"不轻易放过"。

## 与 /goal 搭配

`/goal` 是内置命令：每 turn 结束用小模型查完成条件，未达成就自动再起 turn，适合长跑。它是唯一独立复读 transcript 的一环，也是把"别静默放过 Codex 缺席"从口头变成可检查的唯一着力点——所以每轮三槽状态行必须明确回显在对话里；最终结论 token 只在**终止轮**回显（非终止轮不写，免得被 /goal 误判为完成）。

```
/goal 按 review-loop 流程对本次提案与变更做对抗性 review 循环；完成条件：最近一轮两个 Claude 专家都返回了结论、最终结论行为 APPROVE / CLEAR / APPROVE-DEGRADED 之一、无新增 blocker/major、且 Codex 已给可解析结论或已判定结构性未跑完（瞬态未跑完须继续重试）；轮数上限 10 轮（兜底，可调高；要"跑到放行为止"就删掉本句不设上限），到顶仍未放行则终止、最终 token 记 CAPPED (达上限, 剩 M 项未决)
```

评估器按**字面**判未完成，满足任一即继续跑：① 最近一轮缺三槽状态行；② 任一 Claude 专家槽为空 / 未跑完；③ 任一槽为 `CHANGES-REQUESTED`；④ Codex 槽为 `未跑完(...)` 时，仅当最终 token 为 `APPROVE-DEGRADED` 且其括注原因是**结构性**（未装 / 未登录 / 额度）或 `瞬态, 达上限` 才算可终止；否则——无此 token、或瞬态未到上限却标了 `APPROVE-DEGRADED`——一律继续（防主 agent 把瞬态缺席提前包装成降级放行）；⑤ 最终 token 不在 `APPROVE` / `CLEAR` / `APPROVE-DEGRADED` 内。（两个 Claude 专家槽是归一后结论，"无 CHANGES-REQUESTED 槽"即"无未解决 blocker/major"；但 Codex 槽另有 `未跑完` 第三值，须靠 ④ 单独拦，不能只查 CHANGES-REQUESTED。）

**上限优先**（仅当设了轮数上限时）：①–⑤ 仅在**未到上限**时使循环继续；一旦**到上限**，循环**无条件终止**——放行则记放行 token，仍有未决则记 `CAPPED (达上限, 剩 N 项未决)`。`CAPPED` 是终止 token、不算放行，评估器见它即停、不再起新 turn（这样既守住"不无限循环"，又不会把未放行包装成 APPROVE）。**若完成条件里不设上限**（要"跑到放行为止"），则 `CAPPED` 不触发、上限优先不适用，循环按 ①–⑤ 跑到拿到放行 token 或你中断为止。

> 诚实边界：这是 prose 指令、无运行时强制，只能**降低而非消除**"Codex 静默缺席被当成通过"的概率；真正兜底是上面 /goal 的字面检查。本 skill 依赖模型遵从、不可自动化测试——**但这不豁免任何步骤**：三槽状态行、级别复核与归一、终止判定仍须逐条执行；/goal 只能查到结论行字面存在，查不到归一是否真做，所以归一是不可省的人工步。
