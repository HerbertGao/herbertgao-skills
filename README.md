# herbertgao-skills

HerbertGao 的自托管 AI coding skills 仓库。两条安装线：Claude Code 走 plugin marketplace（保留 `codex:codex-rescue` / `subagent_type` 等 Claude 专属调用）；其它平台走 `npx skills add` 装通用版（平台中立）。

## 前置：agency-agents

`review-loop` / `opsx` 优先用宿主已注册的原生 subagent（`registered` 档），解析不到才读 `~/.agency-agents`。`council` 必须从 catalog 枚举候选席位。catalog 由你自己 clone、控制版本，三个 skill 都只读它。装一次：

```bash
git clone https://github.com/msitarzewski/agency-agents ~/.agency-agents
```

**没装、且该角色也没注册**时：`review-loop` / `opsx` 在层级回显里带上降级原因与补救命令，退到内嵌浓缩 prompt（更弱的专家，终态因此封顶）；`council` 要靠 catalog 枚举候选席位，凑不出一个真专家就 `STOPPED`。

这些 skill 的 SKILL.md 里带着**运行期字符串**（层级 marker、补救命令、catalog 源路径），它们自己的闸门要逐字匹配——错一个字符，闸门就静默失效。所以它们由 [`contracts/format.json`](./contracts/format.json) 定义、[`scripts/check-format.py`](./scripts/check-format.py) 机械校验（每次 push 跑 CI，发版前再跑一遍），并会拿真实 catalog 验证路径表在干净安装上确实解析得到。

## 推荐配套：ponytail

新环境(Claude Code / Codex / Trae / OpenCode)装机时建议顺手装 [ponytail](https://github.com/DietrichGebert/ponytail)(Claude Code 与 Codex 均有包装)——主 agent 的精简纪律(YAGNI 阶梯、最小 diff)。**忘装无硬性后果**:本仓库的 review-loop/council 已把精简阶梯内嵌在 SKILL 文本里,不依赖它;但环境主 agent 的日常写码行为会失去这层约束。无插件机制的环境(Trae/OpenCode 等),把 ponytail 的核心 persona 粘进该环境的全局指令文件(AGENTS.md 等价物)即可,一次性拷贝。

## 安装

### Claude Code — plugin marketplace

```text
/plugin marketplace add HerbertGao/herbertgao-skills
/plugin install review-loop@herbertgao-skills
/plugin install council@herbertgao-skills
/plugin install opsx@herbertgao-skills
```

更新：`/plugin marketplace update herbertgao-skills` 后重装。若装过旧 marketplace，先 `/plugin marketplace remove claude-skills`。`opsx` 另需 `openspec-cn` CLI（不附带）。

### 其它平台（OpenCode / Codex / Trae / Cursor …）— `npx skills add`

```bash
npx skills add HerbertGao/herbertgao-skills --list          # 列出可装 skills
npx skills add HerbertGao/herbertgao-skills                 # 装到自动检测的 agent
npx skills add HerbertGao/herbertgao-skills --agent codex
```

Codex 亦可走原生 marketplace（`codex-plugins/` 下 `SKILL.md` 是 `skills/` 的逐字节副本，附 `agents/openai.yaml` 入口壳）：

```bash
codex plugin marketplace add HerbertGao/herbertgao-skills --ref main
codex plugin add review-loop@herbertgao-skills-codex
codex plugin add council@herbertgao-skills-codex
codex plugin add opsx@herbertgao-skills-codex
```

## 收录的 skill

| Skill | Claude Code（plugin） | 通用版（`npx skills add`） |
| --- | --- | --- |
| `review-loop` | [`review-loop/…/SKILL.md`](./review-loop/skills/review-loop/SKILL.md)：`subagent_type` + Codex rescue lane。 | [`skills/review-loop/SKILL.md`](./skills/review-loop/SKILL.md)：第三审查槽换成平台中立的 `Independent Reviewer`。 |
| `council` | [`council/…/SKILL.md`](./council/skills/council/SKILL.md)：Claude 审计模式 + 能力不足时的 advisory。 | [`skills/council/SKILL.md`](./skills/council/SKILL.md)：平台能力路由；保留专家辩论，按证据能力输出 `CONVERGED` 或 non-authorizing `ADVISORY`。 |
| `opsx`（npx skill 名 `openspec-apply-change-subagent`） | [`opsx/…/SKILL.md`](./opsx/skills/openspec-apply-change-subagent/SKILL.md)：`general-purpose`。 | [`skills/openspec-apply-change-subagent/SKILL.md`](./skills/openspec-apply-change-subagent/SKILL.md)：按 catalog 源路径 + 角色名解析。 |

角色解析梯：`review-loop` / `opsx` 是 `registered → local → embedded`；`council` 是 `catalog → synthesized`——`synthesized`（自撰 persona）最多一席、且不能当反方席，一个真专家都解析不出来就 `STOPPED`。

分界线：**有没有一份写出来的产物**。`review-loop` 撕**已经写出来的东西**——OpenSpec 变更、提案、spec、diff，纯散文提案也归它；`council` 判**还没写下任何产物**的开放决策（选型 / 架构 / 要不要做）。先 council 定方向，再 review-loop 撕产物。

`council` 的核心是四席以上的真实专家 persona、独立首轮、crux、DA/cross-exam 与人类价值裁决。宿主能提供 canonical dispatch/return/tool records 时走 audited mode，审计通过后可输出 `CONVERGED`；只有 fresh-context 席位而缺少这些记录时仍完成辩论，但输出不具认证与实现授权效力的 `ADVISORY`。

语言约定：`council` 与 `review-loop` 全线英文（避免中英孪生漂移）；`opsx` 全线中文（配 openspec-cn）。

**哪份是权威**：`skills/<skill>/SKILL.md` 是 SOT。`codex-plugins/` 下是它的**逐字节副本**（`check-format.py` fail-closed 地守着）。`<plugin>/` 下的 Claude 版是**手工维护的平行副本**；它可在 frontmatter、Platform Adapter 与宿主专属 auditor 机制上不同，共享的辩论和终态语义必须对等。`required_verbatim` 只机械守住 evaluator 会匹配的关键字面量，其余语义仍需 review。

## 结构

```text
herbertgao-skills/
├─ .claude-plugin/marketplace.json   # Claude Code marketplace
├─ review-loop/ · council/ · opsx/   # Claude Code plugin（各自 SOT；review-loop 含 codex:codex-rescue）
├─ skills/                           # 通用版 SOT（npx skills add 安装源）
├─ codex-plugins/                    # Codex 原生入口：SKILL.md 为 skills/ 的逐字节副本 + agents/openai.yaml
├─ .agents/plugins/marketplace.json  # Codex repo-local marketplace
└─ scripts/                          # 发布/同步脚本
```

新增 skill 要改 6 处，缺一处就装不上：

1. `<plugin>/.claude-plugin/plugin.json` — Claude plugin manifest
2. `<plugin>/skills/<skill>/SKILL.md` — Claude 版 SOT
3. `.claude-plugin/marketplace.json` — 追加一条，否则 `/plugin install` 装不上
4. `skills/<skill>/SKILL.md` — 通用版 SOT（平台中立）
5. `codex-plugins/<plugin>/` — `.codex-plugin/plugin.json` + `skills/<skill>/SKILL.md`（第 4 条的逐字节副本）+ `skills/<skill>/agents/openai.yaml`
6. `.agents/plugins/marketplace.json` — 追加一条，否则 `codex plugin add <name>@herbertgao-skills-codex` 失败

## License

MIT
