# herbertgao-skills

HerbertGao 的自托管 AI coding skills 仓库。两条安装线：Claude Code 走 plugin marketplace（保留 `codex:codex-rescue` / `subagent_type` 等 Claude 专属调用）；其它平台走 `npx skills add` 装通用版。

## 安装

### Claude Code — plugin marketplace

```text
/plugin marketplace add HerbertGao/herbertgao-skills
/plugin install review-loop@herbertgao-skills
/plugin install council@herbertgao-skills
/plugin install opsx@herbertgao-skills
```

更新：`/plugin marketplace update herbertgao-skills` 后重装。若装过旧 marketplace，先 `/plugin marketplace remove claude-skills`。

> `opsx` 需要 `openspec-cn` CLI（plugin 不附带，自行安装）。

### 其它平台（OpenCode / Codex / Trae / Cursor …）— `npx skills add`

通用版 skill 在 [`skills/`](./skills)，平台中立，用 [Vercel Labs 的 `skills` CLI](https://github.com/vercel-labs/skills) 安装：

```bash
npx skills add HerbertGao/herbertgao-skills --list          # 列出可装 skills
npx skills add HerbertGao/herbertgao-skills                 # 装到自动检测的 agent
npx skills add HerbertGao/herbertgao-skills --agent opencode
npx skills add HerbertGao/herbertgao-skills --agent codex
```

通用版不调 `codex:codex-rescue`、不用 Claude `subagent_type`；各 skill 的角色解析与 fallback 层数不同，见各自 SKILL.md 的 `Platform Adapter` 章节（`review-loop` 的第三审查槽是平台中立的 `Independent Reviewer` + 四层 fallback；`council` 是三层）。[msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)：对 `review-loop` 是可选的质量增强，对 `council` 是**本体**——一个真专家都解析不出来时 `council` 直接 `STOPPED`，不降格运行。

Codex 亦可走原生 marketplace（`codex-plugins/` 下 `SKILL.md` 是通用版的副本，随 `skills/` 同步，附 `agents/openai.yaml` 入口壳）：

```bash
codex plugin marketplace add HerbertGao/herbertgao-skills --ref main
codex plugin add review-loop@herbertgao-skills-codex
codex plugin add council@herbertgao-skills-codex
codex plugin add opsx@herbertgao-skills-codex
```

## 收录的 skill

| Skill | Claude Code（plugin） | 通用版（`npx skills add`） |
| --- | --- | --- |
| `review-loop` | [`review-loop/…/SKILL.md`](./review-loop/skills/review-loop/SKILL.md)：`subagent_type` + Codex rescue lane。 | [`skills/review-loop/SKILL.md`](./skills/review-loop/SKILL.md)：平台中立，`Independent Reviewer` + 逻辑角色名 + 四层 fallback。 |
| `council` | [`council/…/SKILL.md`](./council/skills/council/SKILL.md)：`subagent_type` + `AskUserQuestion` 拍板。 | [`skills/council/SKILL.md`](./skills/council/SKILL.md)：平台中立，generic subagent + 三层 fallback。 |
| `opsx`（npx skill 名 `openspec-apply-change-subagent`） | [`opsx/…/SKILL.md`](./opsx/skills/openspec-apply-change-subagent/SKILL.md)：`general-purpose`。 | [`skills/openspec-apply-change-subagent/SKILL.md`](./skills/openspec-apply-change-subagent/SKILL.md)：平台中立，`slugify(name)` + 四层 fallback。 |

分界线：**有没有一份写出来的产物**。`review-loop` 撕**已经写出来的东西**——OpenSpec 变更、提案、spec、diff，**纯散文提案也归它**；`council` 判**还没写下任何产物**的开放决策（选型 / 架构 / 要不要做）。先 council 定方向，再 review-loop 撕产物。

语言约定：`council` 与 `review-loop` 全线英文（避免中英孪生漂移）；`opsx` 全线中文（配 openspec-cn）。

`review-loop` 有两条**站桩的反压**，防的是循环自己的产出物变质——因为循环是**只插不删**的：

- **简洁性（ponytail 透镜）**：每一轮修复都在加代码，严重度在排空、行数在爬升，而没有任何一条审查线看得见「臃肿」。它把这件事变成一个数字（`net: -N`）。
- **可读性（冷读透镜，§1f）**：当被 review 的是**散文**（spec / 提案 / ADR / OpenSpec 变更 / SKILL.md / README）时，每一轮的修复会落在「发现问题的那一处」而不是「读者需要它的那一处」，循环里现造的术语从不定义，规则的**理由**被压掉——终态是一堆**只有产出它的那个循环才读得懂的补丁**。它派一个**没看过这个循环**的冷读者，只给它文档本身，问五个问题（这是干什么的？什么时候不该用？改 X 要动哪儿？哪些术语没定义？**哪些规则你根本没法遵守？**）。最后一问不是文风问题：**一条读者无法满足的规则就是装饰，而 spec 里的装饰比缺一条规则更糟——它制造了一道并不存在的闸门的假象。**

## 结构

```text
herbertgao-skills/
├─ .claude-plugin/marketplace.json   # Claude Code marketplace
├─ review-loop/ · council/ · opsx/   # Claude Code plugin（各自 SOT；review-loop 含 codex:codex-rescue）
├─ skills/                           # 通用版 SOT（npx skills add 安装源）
│  ├─ review-loop/SKILL.md
│  ├─ council/SKILL.md
│  └─ openspec-apply-change-subagent/SKILL.md
├─ codex-plugins/                    # Codex 原生入口：SKILL.md 为 skills/ 的副本，附 skills/<skill>/agents/openai.yaml
├─ .agents/plugins/marketplace.json  # Codex repo-local marketplace
└─ scripts/                          # 发布/同步脚本
```

新增 skill 要改 6 处，缺一处就装不上：

1. `<plugin>/.claude-plugin/plugin.json` — Claude plugin manifest
2. `<plugin>/skills/<skill>/SKILL.md` — Claude 版 SOT
3. `.claude-plugin/marketplace.json` — 追加一条，否则 `/plugin install` 装不上
4. `skills/<skill>/SKILL.md` — 通用版 SOT（平台中立）
5. `codex-plugins/<plugin>/` — `.codex-plugin/plugin.json` + `skills/<skill>/SKILL.md`（第 4 条的逐字节副本，随 `skills/` 同步）+ `skills/<skill>/agents/openai.yaml`
6. `.agents/plugins/marketplace.json` — 追加一条，否则 `codex plugin add <name>@herbertgao-skills-codex` 失败

## License

MIT
