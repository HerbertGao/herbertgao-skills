# herbertgao-skills

HerbertGao 的自托管 AI coding skills 仓库。两条安装线：Claude Code 走 plugin marketplace（保留 `codex:codex-rescue` / `subagent_type` 等 Claude 专属调用）；其它平台走 `npx skills add` 装通用版。

## 安装

### Claude Code — plugin marketplace

```text
/plugin marketplace add HerbertGao/herbertgao-skills
/plugin install review-loop@herbertgao-skills
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

通用版不调 `codex:codex-rescue`、不用 Claude `subagent_type`，第三审查槽为平台中立的 `Independent Reviewer`；解析规则与四层 fallback 见各 SKILL.md 的 `Platform Adapter` 章节。可选装 [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) 作为一级来源（质量增强，非硬依赖）。

Codex 亦可走原生 marketplace（`codex-plugins/` 下 `SKILL.md` 是通用版的副本，随 `skills/` 同步，附 `agents/openai.yaml` 入口壳）：

```bash
codex plugin marketplace add HerbertGao/herbertgao-skills --ref main
codex plugin add review-loop@herbertgao-skills-codex
codex plugin add opsx@herbertgao-skills-codex
```

## 收录的 skill

| Skill | Claude Code（plugin） | 通用版（`npx skills add`） |
| --- | --- | --- |
| `review-loop` | [`review-loop/…/SKILL.md`](./review-loop/skills/review-loop/SKILL.md)：`subagent_type` + Codex rescue lane。 | [`skills/review-loop/SKILL.md`](./skills/review-loop/SKILL.md)：平台中立，`Independent Reviewer` + 逻辑角色名 + 四层 fallback。 |
| `opsx`（npx skill 名 `openspec-apply-change-subagent`） | [`opsx/…/SKILL.md`](./opsx/skills/openspec-apply-change-subagent/SKILL.md)：`general-purpose`。 | [`skills/openspec-apply-change-subagent/SKILL.md`](./skills/openspec-apply-change-subagent/SKILL.md)：平台中立，`slugify(name)` + 四层 fallback。 |

## 结构

```text
herbertgao-skills/
├─ .claude-plugin/marketplace.json   # Claude Code marketplace
├─ review-loop/ · opsx/              # Claude Code plugin（SOT，含 codex:codex-rescue）
├─ skills/                           # 通用版 SOT（npx skills add 安装源）
│  ├─ review-loop/SKILL.md
│  └─ openspec-apply-change-subagent/SKILL.md
├─ codex-plugins/                    # Codex 原生入口：SKILL.md 为 skills/ 的副本，附 agents/openai.yaml
├─ .agents/plugins/marketplace.json  # Codex repo-local marketplace
└─ scripts/                          # 发布/同步脚本
```

新增 skill：Claude 版加 `<plugin>/` 目录并在 `.claude-plugin/marketplace.json` 追加一条；通用版加 `skills/<skill>/SKILL.md`，需要 Codex 原生入口时把该 `SKILL.md` 拷一份到 `codex-plugins/<plugin>/skills/<skill>/`（与 `skills/` 保持同步）并保留 `agents/openai.yaml`。

## License

MIT
