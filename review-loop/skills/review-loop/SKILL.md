---
name: review-loop
description: 对本次提案与代码变更跑对抗性 review 自动循环——每轮三方并行 Codex（codex:codex-rescue）+ Code Reviewer + Reality Checker（失败枚举 pass），合并去重后 triage，默认派 Minimal Change Engineer 修复，再重新 review，循环到放行（APPROVE/CLEAR；Codex 结构性未跑完时 APPROVE-DEGRADED）或到轮数上限（可配置安全兜底，默认 10，/goal 下可不设）。用户说「对本次提案/变更做对抗性 review 循环」「用 Codex 对本次变更 review 循环」「review 到通过为止」时触发；常配合内置命令 /goal。
---

# review-loop

对「本次提案 + 本次代码变更」做对抗性 review 并自动迭代到通过。每轮：派 reviewer → triage → 派修复 → 重新 review，直到放行或撞上限。直接 `/review-loop` 调用；长跑用 `/goal` 包住（见末节）。

## 结论口径

子代理常不照规范（写错 token、级别拍脑袋、不给结论行）。**主 agent 收到结论后按本节自行归一，不被子代理写的 token 带跑。**

**严重级别**（每条问题必带其一）：

- **blocker** —— 发布即坏：错误结果 / 数据损坏 / 崩溃、安全漏洞、与依赖方契约或 schema 不兼容、核心场景不可用。必须修才放行。
- **major** —— 重要缺陷：设计缺陷、漏掉的失败模式或边界、与既有代码明显不一致、缺关键校验。默认修；确实不修须按「未解决」定义复核降级，不能级别不变只记理由。
- **minor** —— 不影响正确性的局部小问题。按成本收益修。
- **nit** —— 纯风格 / 措辞 / 格式。通常不修。

**结论 token**：放行 = `APPROVE`（Reality Checker 习惯写 `CLEAR`，等价）；打回 = `CHANGES-REQUESTED`（写成 `NEEDS WORK` 同义，按打回处理）。

**先复核级别**：子代理自填的级别常拍脑袋。主 agent 按上面定义对每条问题**重新定级**——既把被低标的 blocker/major 提上来（尤其子代理打回却把理由标成 minor/nit 时），也把被高标的压下去。**下调只在按定义重判确实落到更低档时才成立**；说不出哪条定义把原档判错、纯为终止而降级，本身算未解决。

**「未解决」的定义**：一条 blocker/major 只有在**已修复**、或**主 agent 复核后显式降级为 minor/nit 或判定不适用**时才算已解决；仅口头记个理由跳过、级别不变，仍算**未解决**。

**归一硬规则**：复核后，清单含未解决 blocker/major ⇒ 该结论按**打回**计（哪怕子代理写了 APPROVE）；只剩 minor/nit ⇒ 按**放行**计。**本 skill 全程的「放行 / 打回」都指归一后结论，不是子代理末尾 token。**

`APPROVE-DEGRADED`（降级放行）与 `CAPPED`（达上限未放行）是**主 agent 专用终止 token、非子代理 token、不入任何槽**——见终止条件。

## 循环

### 1. 派 reviewer

同一条消息并行派三方。每个 prompt 自包含：本次提案与变更、对照的真理源（spec / 契约 / 既有代码；**Reality Checker 槽按 §1b 视其为待证基准、不默认代码已符合**）、前轮已修过什么（要找**新** ship-blocker；**Reality Checker 槽例外——此项按 §1b 输入规则剥离，§1b 局部规则覆盖本句**）、**级别定义**、并要求**末尾恰好一行 `APPROVE` / `CHANGES-REQUESTED` + 问题清单（级别 / 位置 / 说明 / 改法）**。

- **Codex** —— `subagent_type: codex:codex-rescue`，只读 review。这是循环唯一能自动派的 Codex 路径（`/codex:adversarial-review` 是人工命令、且不吐结论行，循环不调它）。prompt 必须明确要它给结论行（Codex 默认只返回散文）。
- **Code Reviewer** —— `subagent_type: "Code Reviewer"`。correctness / 契约 / 边界 / 安全 / 与既有代码一致性。**额外产出**：一份 guard/check 清单（每个 if/早返/err 分支/异常 catch/assert/校验/退出码判断），**范围与 §1b 机械枚举同口径**——diff 改动行 + 被改动直接波及的未改 call site/helper/cleanup/测试，供 §1b 表双向对账（机械枚举、低判断、可被对账核验，不增判断负载）。
- **Reality Checker** —— `subagent_type: "Reality Checker"`，按 **§1b 失败枚举 pass** 派。

子代理未注册则回退 `subagent_type: general-purpose`（自写强对抗 prompt；回退 Code Reviewer 时须带上 guard 清单产出要求）。**Code Reviewer 既是语义 reviewer、又是弱对账的锚**：它若返回 `APPROVE` 却**漏产 guard/check 清单**，主 agent 归一时该槽记 `未跑完(缺 guard 清单)`、不算放行（否则缺锚的弱对账被当完整）。安全敏感面再加 `subagent_type: "Security Engineer"`——**其结论恒并入 Code Reviewer 槽**（不另开第四槽，守住三槽不变量），finding 照常进 §2 triage。

> `Code Reviewer` / `Reality Checker` / `Security Engineer` / `Minimal Change Engineer` 来自 agency-agents 合集：`github.com/msitarzewski/agency-agents`（`engineering/` 与 `testing/` 目录）；`subagent_type` 用各 agent frontmatter 的 `name`。本机缺失时从该 repo 安装，或先用 `general-purpose` 回退跑。

**确定性前置门**（对跑 loop 可选，对干净 `APPROVE` 必需）。栈有现成静态分析（shellcheck / clippy / ruff 开 encoding 规则 / 已有 CI 契约检查 / AST 或 grep 抽 guard 点）时，主 agent 派 reviewer **前**先跑：命中作为额外 finding 进 §2 triage，**且其抽出的 guard 点清单作为 §1b 完整性对账的机械锚（= 强对账）**（见 §1b）。**「可选」指不跑也能跑完 loop（封顶 `APPROVE-DEGRADED`）、不是「跑不跑都一样」**——跑了才解锁干净 `APPROVE`（强对账）。便宜、栈相关，多半是「规则没开」而非架构缺；不占状态槽，**不替代** §1b。

**每轮必回显一行三槽状态**（子代理失败返回空，与「无问题」不可区分；空槽不许默认成放行）。槽位写**归一后结论**、不是子代理原 token：

```
本轮 reviewer：Code Reviewer=APPROVE │ Reality Checker(§1b)=CHANGES-REQUESTED │ Codex=未跑完(空返回)
```

Codex 槽只写 `APPROVE` / `CHANGES-REQUESTED` / `未跑完(原因)`；`APPROVE-DEGRADED` 只出现在最终聚合结论行，不入任何槽。

### 1b. 失败枚举 pass（Reality Checker 槽）

普通 prose reviewer（Code Reviewer / Codex 等语义型）倾向验 happy path + 已写断言，对「失败路径 × 边界 × 假绿」系统性漏——这是经验上 review 放过、事后才被静态 bot 抓到的最大一类。根因不是缺 mandate，而是缺**强制枚举结构** + **上下文污染**（与设计叙事、绿测同读，「测过了」成锚点）。故 Reality Checker 槽按两阶段结构跑、且**输入去污染**：

**输入规则**——prompt 给 diff + 对照真理源（spec / 契约），但**剥掉评价性框架**：不给「已 N 轮 APPROVE」「测试已过」「方案已成熟」「这块前轮已修无须再看」等任何**评价/结论性**框架（防「它没问题 / 这块已结」成锚点）。真理源标为**待证基准而非已证**（判「契约声称 vs 观察」要用它，但不默认代码已符合它）。**但区分污染与必要状态**：仍给一份**中性机读 row 台账**——只含 `行 ID + 二值「本轮 fix 是否触及该行(及其依赖)」`，**不含**具体终态值（`verified-safe` / `accepted-degraded` 本身就是 verdict，回灌即「上轮判过 safe」锚点，等于没剥）、也不含任何好评 / 「已 OK」措辞。台账只回答「哪些行被这轮 fix 动过、需重新枚举」，**不回答「哪些行上轮判安全可跳过」**——被触及的行一律重验，未触及的行下轮照常重新枚举（去污染不等于免重验）。**成本说明**：大表 + 小步 fix 下，「未触及行也重枚举」使单轮 §1b 成本 ∝ 全表（轮数仍单调收敛、不死锁，炸的是单轮成本不是轮数）。缓解：**有强对账时**，未触及行的「是否仍枚举全」交确定性前置门机械重抽（几乎零成本），prose 只重验被触及行 + 前置门新报点；**无前置门栈**承认这是弱对账的固有成本（列入预期管理），可人工分块 diff。这正是「去污染（不回灌终态）」与「增量省成本」的张力——本 skill 选不回灌（防假绿）、用前置门而非回灌来省成本。

1. **机械枚举（只列不判）**：把每个 ①guard / 早返 / `err` 分支 / 异常 catch ②assert / 校验 / 退出码判断 ③状态转移（重启 / 重连 / 续期 / cleanup / dry-run）④「声称通过」点（测试断言 / cassette / 复算列 / doctor 检查）逐个列成**带 `文件:行号` 的表**。**枚举范围 = diff 改动行 + 被改动直接波及的未改代码**：改了契约/签名/返回语义的**未改调用方**、被调用的 helper、未改的 cleanup/finally 路径、断言依赖已改行为的**未改测试/CI** 都要进表——回归常藏在「未改但被 diff 变可达/变失效」的代码里，只枚举改动行的 gate 会放过它。
2. **逐行对抗**：每行实例化失败输入 `{empty / null / malformed / timeout / partial-write / restart-mid-op / 并发双驱动 / 返错而非返值 / token 过期 / 查询零行 / -1 瞬断}`，写「观察行为 vs 契约声称」。任一「报成功但底层坏了或在撒谎」= blocker（容错降级 ≠ 撒谎，按契约基准区分）。契约对某点**沉默**（spec 未规定该失败输入的行为）时，记为 finding「行为未定义、契约缺规定」，不默认放过。
3. **表外尾巴**：表枚举不到的不可测验收 / 伪验收 / 整体方案不可证，附末尾。

**harness 假绿子模板**——diff 含**任何测试 / CI-CD / soak / doctor / 产「通过·绿」信号的文件时**（按内容意图判定、不限目录；如 `tests/`、`*.sh`、`conftest.py`、`Makefile`/`pyproject` 测试配置、`*.bats`、`Dockerfile`、CI yaml、`doctor`）**额外逐项过**：vacuous assert（恒真 / 对 mock 自身断言）/ 吞异常后标成功 / cassette 录自坏掉的 run / 空刷写废档 / 写失败仍标 flushed / 检查在查询失败或零行时仍 `return 0`。这是经验上最 bug 密集的区域（「证据本身会撒谎」），与生产失败注入正交、须单列。

**完整性对账**：本表不可只靠自觉（prose reviewer 易 satisfice，列几个就停）。优先级：① 栈有**确定性前置门**（shellcheck/clippy/grep/AST 抽分支）时，用它机械抽出的 guard 点清单对账——这是唯一**不依赖 prose 判断**的完整性源，称**强对账**；② 无前置门时退回用 Code Reviewer 独立产的清单交叉对账，两边都是 prose、可能漏同一点，称**弱对账（概率性、非完备）**。

对账须**双向行身份**、防 umbrella 行掺水：清单里每个 guard 必须**一一映射**到表里恰好一行（按 `文件 + 行号/范围 + 句法类型 + 局部代码片段` 匹配，编辑后行号漂移用片段兜底）；**不许把多个 guard 并成一条宽泛行**充数（合并行不计为已枚举各点）。两向都查——**清单有表无 = 漏列**（记未处理行）；**表有清单无 = 存疑行**（要么是清单漏抽、要么是表虚构，须核对）。**无任何对账 → 视表不完整、gate 不放行**。

**强弱对账影响放行档位**（见终止条件）：**强对账**通过方可干净 `APPROVE`；**弱对账**因完整性不可证（两 prose 同点同漏 = 已知假绿模式），**最高只到 `APPROVE-DEGRADED (弱对账:非完备)`、永不发干净 APPROVE**——与 Codex 结构性缺席同档处理，不把已知假绿模式洗成干净放行。

**预期管理**：没接确定性前置门的项目（多数 shell / 文档 / 未配静态分析的小仓）因此**正常稳态就是 `APPROVE-DEGRADED (弱对账:非完备)`，干净 `APPROVE` 是「已接 shellcheck/clippy/AST 等机械锚」的栈才解锁的更高档**——这是设计意图、**不是降格惩罚或系统故障**；想要干净 APPROVE 就接一个轻量前置门（哪怕 grep 抽 guard 点）。别因为「总不给 APPROVE」就以为 loop 坏了。

**覆盖边界（诚实声明）**：本 pass 只打失败路径 / 边界 / 并发假绿。**叙事漂移**（doc/spec 说 X 代码做 Y）与**前向脆弱**（现在对、未来静默坏）是**正交的另一类分布，本 prose loop 不可靠覆盖**——经验上它属 BugBot/Copilot 这类静态 bot 的擅长面，prose reviewer 复刻不收敛到其覆盖。故**不在本 loop 的保证范围**：要覆盖就靠 loop 外的 bot（BugBot/Copilot）当 gate；无 bot 时，这两类作为**已知残留**列入终止时的诚实边界（同 Codex 结构性缺席的处理逻辑），不假装已覆盖、也不靠一句无探针的「必做」自欺。**严禁**把「跑了失败枚举」当成对这两类的放行。

输出 = 枚举表 + 每行**终态** + 表外尾巴，结论按统一格式回到 Reality Checker 槽，转 finding 的行并入 §2 triage。**行终态四选一**，gate 查的是终态、不是「有没有 disposition」（防把硬行经主观 triage 静默洗白）：

- `verified-safe` —— 该行已逐失败输入验过、行为符合契约。**不是裸标签**：须随行**附证据**（实例化了哪些失败输入 + 各自观察行为 vs 契约声称），主 agent triage 时抽审；只打标签不展示验证过程的，按 `unresolved` 计。**附证据焊死的是「标签真值」（有没有验），不是「证据充分性」（举的失败输入集有没有漏掉真正会炸的那个）**：充分性只在**强对账**下机械可证（前置门抽出的 guard 点逐点比对）；**弱对账栈下抽审是概率性的，与 L71「两 prose 同点同漏」是同一假绿模式**——故弱对账栈即便满表 verified-safe 也封顶 `APPROVE-DEGRADED`、不发干净 APPROVE（别高估弱对账下 verified-safe 的保证强度）。对账的「同位交叉」交叉的是**行是否被枚举**（行身份），**不**核验各行证据内容，不要当成充分性探针。
- `fixed` —— 转 finding 且已修复（附修复指向）。
- `accepted-degraded` —— 复核后显式降级 / 判不适用，**须附按严重级别定义可审计的理由**——即 §结论口径的「复核降级」在行级的落点（同义、非第二套门槛）；理由说不出哪条定义把原档判错 = 仍算 `unresolved`。
- `unresolved` —— 未验 / 未修 / 理由不成立 / 终态无证据。

**只有全部行 ∈ {`verified-safe`, `fixed`} 才满足干净 `APPROVE` 的 gate**；含 `accepted-degraded` → 最高 `APPROVE-DEGRADED`；含 `unresolved` → 打回。（对账里的**存疑行**核对后也须落上述某一终态，不许悬空。）

### 2. Triage

各来源问题（三方 + 可选前置门）**合并去重成一份**（同一处别派两套改法），按「结论口径」**复核定级**，逐条判断：blocker/major 默认修；确实不修的 major 必须主 agent **复核降级**（按定义重判为 minor/nit 或判定不适用）再记理由——不能级别不变只口头跳过；minor/nit 按收益。向用户说明修哪些、跳哪些。无值得修的问题 → 终止条件。

### 3. 派修复

修复默认派子代理（干净上下文，不带主线设计的先入为主）。按类型选执行者：

- **默认** `subagent_type: "Minimal Change Engineer"`（最小 diff、拒绝 scope creep；未注册回退 `general-purpose`）——局部 bug、单模块、照 spec 的机械改动。
- **大型复杂**（跨模块 / 服务边界、需重推架构或数据流、schema/API 迁移、需设计测试策略）`subagent_type: codex:codex-rescue`。
- **OpenSpec 纯文档机械修复**（措辞 / 格式 / 补齐已定方案）主 agent 直接改；涉及需求语义或契约判断则按上两档分流。

**主 agent 写完整修复 spec**——每问题给文件路径、具体改法、验收方式。prompt 交代边界：先做 spec 内无争议项；只有新发现会使 spec 出错 / 引入回归 / 需扩大范围时才暂停回报，其余相邻小问题只记不擅自扩。

### 4. 重新 review

回步骤 1 三方并行重试（Codex 可能中途恢复）。「每轮重试」只在循环将继续（仍有未解决 blocker/major）时适用；若两个 Claude 专家本轮**归一后**均放行，进终止条件判干净 / 降级 / 继续（干净终止另受放行 gate 约束，见下）。「不为再试一次 Codex 多跑一轮」只针对 Codex 已给结论或属结构性的情况；Codex 属**瞬态**未跑完时，按终止条件仍需下一轮重试。

## 终止条件

预期 reviewer 恒为三方；Codex 未出可解析结论一律算「未跑完」，分两类：

- **瞬态**（空返回 / 跑了但没给结论行）—— 下一轮用更严 prompt（「末尾只输出一行 verdict」）重试，**不早停**。Codex 跑了只是没吐结论行 ≠ 它否决，不可据此报 APPROVE-DEGRADED。
- **结构性**（未装 / 未登录 / 额度，本会话不会自行恢复）—— 重试无意义。
- **判不准属哪类**按**瞬态**处理（重试；后续轮出现明确信号——如「未登录」——再转结构性）。默认走安全侧：误判只多费几轮、不假放行。

**放行 gate**——任何**放行类终止**（`APPROVE` / `CLEAR` / `APPROVE-DEGRADED`，含到顶降级）前必须满足：① §1b 枚举表每行有**终态**（非「有无 disposition」）；② 表已过完整性对账、双向行身份无漏列/无未核存疑行；③ 表转出的 finding 走完 §2 triage、归一后无未解决 blocker/major。仅「三方都写 APPROVE」不构成放行——否则 loop 的退出条件本身就是它要抓的那种假绿。gate 卡的是**枚举完整性 + 行终态**，不是「零 finding」；finding 经复核合法降级（`accepted-degraded` 带可审计理由）后不阻塞放行，但拉低放行档位（见下）。

**放行档位**（取最严者）：全行 ∈ {verified-safe, fixed}、**强对账**通过、Codex 给结论 → 干净 `APPROVE`；任一为 `accepted-degraded`、或仅**弱对账**、或 Codex 结构性缺席 → 最高 `APPROVE-DEGRADED`（括注全部降级因，如 `APPROVE-DEGRADED (弱对账:非完备; Codex:未登录)`）；任一 `unresolved` 或对账不可过 → 打回 / `CAPPED`。

判定：

- **干净终止**：三方本轮都实际跑成（Codex 给了可解析结论）、**归一后均放行**、**放行 gate 满足、且达干净 APPROVE 档位**（全行 verified-safe/fixed + **强对账**通过）→ 以 `APPROVE` / `CLEAR` 结束。至少两个 Claude 专家都返回了结论；某专家（非 Codex）未返回按未完成处理（重试或回退 `general-purpose` 补齐），不可仅凭单个专家放行就终止。任一打回即继续。
- **Codex 瞬态未跑完**：两专家归一后放行、gate 满足，但 Codex **瞬态**未跑完 → **不终止也不降级**，下一轮按瞬态规则重试，直到它给结论（→ 干净终止）、转结构性（→ 降级终止）、或撞上限。
- **降级终止**：两专家归一后均放行、gate 满足，但**只够 APPROVE-DEGRADED 档位**——即出现下列任一不可消除的降级因：**(a)** Codex 属**结构性**未跑完；**(b)** 无确定性前置门、只能**弱对账**（完整性不可证）；**(c)** 有行终态为 `accepted-degraded` → **立即停止**（继续重审不产新信息），结论用 `APPROVE-DEGRADED` 并**括注全部降级因**（如 `APPROVE-DEGRADED (Codex 未跑完: 未登录; 弱对账:非完备)`），不报成干净 APPROVE。其中 (b) 弱对账：要消除须接入确定性前置门（强对账），否则这是该栈的固有上限、不再多跑。
- **轮数上限**：一个**可配置安全兜底**——防病态不收敛（修复反复引入新问题、两 reviewer 长期僵持），**不是「够好了就停」的质量门槛**。默认 **10 轮**，嫌不够直接调高（10–20 常见）。真正的终结是**收敛**（拿到放行 token）或 /goal 里写的完成条件，不是这个数。
  - **设了上限、到顶必须终止**（守住「不无限循环」）：两专家已放行、gate 满足、仅 Codex **瞬态**未跑完 → `APPROVE-DEGRADED (…: 瞬态, 达上限)`；仍有未解决 blocker/major、gate 未满足、或某 Claude 专家槽仍 `CHANGES-REQUESTED` / 空 / 未跑完 → `CAPPED (达上限, 剩 N 项未决)` 并列出未决项——**终止 token、明确不是放行**。
  - **/goal 下可不设上限**：此时 `CAPPED` 不触发，循环只在拿到放行 token 或你中断时结束——用「可能长跑」换「不轻易放过」。

## 与 /goal 搭配

`/goal` 是内置命令：每 turn 结束用小模型查完成条件，未达成就自动再起 turn，适合长跑。它是唯一独立复读 transcript 的一环，也是把「别静默放过 Codex 缺席 / 别跳过 gate」从口头变可检查的着力点——所以每轮三槽状态行必须明确回显；最终结论 token 只在**终止轮**回显（非终止轮不写，免得被误判为完成）。

```
/goal 按 review-loop 流程对本次变更做对抗性 review 循环；完成条件：最近一轮两个 Claude 专家都返回了结论、放行 gate 满足（§1b 表每行有终态、双向行身份对账无漏列/无未核存疑行、归一后无 blocker/major；干净 APPROVE 另需全行 verified-safe/fixed + 强对账，仅弱对账或有 accepted-degraded 行则最高 APPROVE-DEGRADED）、最终结论行为 APPROVE / CLEAR / APPROVE-DEGRADED 之一、且 Codex 已给可解析结论或已判定结构性未跑完（瞬态须继续重试）；轮数上限 10 轮（兜底，可调高；要「跑到放行为止」就删掉本句不设上限），到顶仍未放行则终止、最终 token 记 CAPPED (达上限, 剩 M 项未决)
```

评估器按**字面**判未完成，满足任一即继续跑（每条编号 = 一个独立可字面判的 continue 谓词）：

- **①** 最近一轮缺三槽状态行；
- **②** 任一 Claude 专家槽为空 / 未跑完；
- **③** 任一槽为 `CHANGES-REQUESTED`；
- **④** Codex 槽为 `未跑完(...)` 时，仅当最终 token 为 `APPROVE-DEGRADED` 且括注原因是**结构性**或 `瞬态, 达上限` 才算可终止，否则一律继续（防把瞬态缺席提前包装成降级放行）；
- **⑤** 最终 token 主体不在 `APPROVE` / `CLEAR` / `APPROVE-DEGRADED` 内（白名单**按 token 主体匹配、忽略括注/后缀**——故 `APPROVE (… 未覆盖 …)`、`APPROVE-DEGRADED (Codex …)` 等带后缀形按主体命中、不算「不在白名单」；各后缀的必要性由 ④（Codex 证据）/ ⑦（降级因）/ ⑧（叙事漂移注明）各自另查，与本条主体匹配共存不冲突）；
- **⑥** §1b 枚举表缺失 / 有 `unresolved` 行或行无终态 / 未过双向完整性对账 → 继续（防跳过强制结构直接 prose 放行）；
- **⑦** 最终为**干净 `APPROVE`**（无降级后缀）却本轮**未跑强对账**（无确定性前置门、只弱对账）或**有 `accepted-degraded` 行** → 继续（弱对账 / 降级行不得发干净 APPROVE，须改 `APPROVE-DEGRADED`；反之 `APPROVE-DEGRADED` 带后缀、不触发本条）；
- **⑧** 本轮 BugBot/Copilot 等外部 bot **未产出对叙事漂移/前向脆弱的覆盖结论**（无 bot，或配了但本轮未跑成/未出结论——按**行为性**判，不按「是否配置」）、且最终为放行/终止 token 时，结论行缺 `叙事漂移/前向脆弱: 未覆盖` 注明 → 继续（迫使该残留被显式披露；这是 §1b 覆盖边界外那一类的探针，与 ④ 之于 Codex 缺席对称）。

**上限优先**（仅当设了轮数上限时）：①–⑧ 仅在**未到上限**时使循环继续；一旦**到上限**，循环**无条件停止干活**，但「停止」≠「可分类为放行」：到顶**仅放行 gate 仍可验证满足时**才记放行 token（含 `APPROVE-DEGRADED`），**§1b 表缺失 / 行无终态 / 完整性对账不可字面核实时一律记 `CAPPED`、绝不发放行 token**（评估器停跑不等于 gate 自动通过——不许用「到顶无条件终止」把未验的表洗成放行）。仍有未决则记 `CAPPED (达上限, 剩 N 项未决)`，列出未决项。`CAPPED` 是终止 token、不算放行，评估器见它即停。（无外部 bot 覆盖**评估器 ⑧ 所指的叙事漂移/前向脆弱**时，所记的放行/CAPPED token **仍须按诚实边界带** `叙事漂移/前向脆弱: 未覆盖` 后缀——记录规则、不因到顶豁免。）**不设上限**时（要「跑到放行为止」），`CAPPED` 不触发，循环按 ①–⑧ 跑到拿到放行 token 或你中断为止。

> 诚实边界：这是 prose 指令、无运行时强制，只能**降低而非消除**「假绿被当成通过」的概率（含 Codex 静默缺席、§1b 表列不全）。**且本 loop 不保证覆盖叙事漂移 / 前向脆弱**（见 §1b 覆盖边界）——无 BugBot/Copilot 当 gate 时，**任何放行/终止 token 必须带注明后缀**，形如 `APPROVE (叙事漂移/前向脆弱: 未覆盖, 交外部 bot 或人工)` 或 `CAPPED (…; 叙事漂移/前向脆弱: 未覆盖)`，与 `APPROVE-DEGRADED` 的诚实括注同理；它不计入放行 gate、也不假装已查，但由评估器 ⑧ 字面校验其存在（缺则继续），使这条「须注明」从 prose 期望变为可检查项、不再是无探针的自欺。真正兜底是 /goal 的字面检查 + §1b 与 Code Reviewer 清单的交叉对账——但这不豁免任何步骤：三槽状态行、级别复核与归一、放行 gate、终止判定仍须逐条执行。
