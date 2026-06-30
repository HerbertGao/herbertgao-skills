# herbertgao-skills

HerbertGao 的自托管 AI coding skills 仓库。主线保留 Claude Code plugin marketplace，同时提供 Codex 与 OpenCode 的平台适配版，避免把 Claude/Codex/OpenCode 的 subagent 调用语义混在一起。

## 安装

### Claude Code

```text
/plugin marketplace add HerbertGao/herbertgao-skills
/plugin install review-loop@herbertgao-skills
/plugin install opsx@herbertgao-skills
```

更新：`/plugin marketplace update herbertgao-skills` 后重装对应 plugin。

如果你已安装旧 marketplace，先移除旧入口后再添加新入口：

```text
/plugin marketplace remove claude-skills
```

> 注：`opsx` 需要 `openspec-cn` CLI（plugin 不附带，请自行安装）。若你此前已在 `~/.claude` 手动放过同名 command/skill，安装本 plugin 会产生重复，二选一即可。

### Codex

Codex 版放在 [`codex-plugins/`](./codex-plugins)，并通过 repo-local marketplace 暴露：

```text
.agents/plugins/marketplace.json
```

本地开发时，从仓根显式添加 marketplace 并安装：

```bash
codex plugin marketplace add .
codex plugin add review-loop@herbertgao-skills-codex
codex plugin add opsx@herbertgao-skills-codex
```

从 GitHub 安装时：

```bash
codex plugin marketplace add HerbertGao/herbertgao-skills --ref main
codex plugin add review-loop@herbertgao-skills-codex
codex plugin add opsx@herbertgao-skills-codex
```

Codex 版使用 Codex 自己的 subagent/custom agent 机制。若已按 `msitarzewski/agency-agents` 安装 custom agents，会使用 `Code Reviewer`、`Reality Checker`、`Minimal Change Engineer`；否则降级为 Codex worker/default subagent 加内嵌角色 prompt。

### OpenCode

OpenCode 版放在 [`.opencode/`](./.opencode)：

```text
.opencode/
├─ commands/
│  ├─ opsx-apply-subagent.md
│  └─ review-loop.md
└─ skills/
   ├─ openspec-apply-change-subagent/
   └─ review-loop/
```

把这些文件复制到目标项目的 `.opencode/` 或全局 `~/.config/opencode/` 后使用。OpenCode 版使用 OpenCode 自己的 `mode: subagent` agents，例如 `@engineering-code-reviewer`、`@testing-reality-checker`、`@engineering-minimal-change-engineer`。这些 `@...` agents 来自 `msitarzewski/agency-agents` 的 OpenCode 安装结果，通常位于 `~/.config/opencode/agents/`；若未安装，Skill 会降级为 generic OpenCode subagent/fallback。它不会调用 Codex subagent，也不会使用 `codex:codex-rescue`。

## 收录的 skill

| Skill | Claude Code | Codex | OpenCode |
| --- | --- | --- | --- |
| `review-loop` | [`review-loop/skills/review-loop/SKILL.md`](./review-loop/skills/review-loop/SKILL.md)：Claude Agent tool + `subagent_type`，保留原 Codex rescue lane。 | [`codex-plugins/review-loop/skills/review-loop/SKILL.md`](./codex-plugins/review-loop/skills/review-loop/SKILL.md)：Codex subagents/custom agents；第三审查槽改为平台中立 `Independent Reviewer`。 | [`.opencode/skills/review-loop/SKILL.md`](./.opencode/skills/review-loop/SKILL.md)：OpenCode `@...` subagents；不调用 Codex。 |
| `opsx` | [`opsx/skills/openspec-apply-change-subagent/SKILL.md`](./opsx/skills/openspec-apply-change-subagent/SKILL.md)：Claude Agent tool + `general-purpose`。 | [`codex-plugins/opsx/skills/openspec-apply-change-subagent/SKILL.md`](./codex-plugins/opsx/skills/openspec-apply-change-subagent/SKILL.md)：Codex worker/custom agents。 | [`.opencode/skills/openspec-apply-change-subagent/SKILL.md`](./.opencode/skills/openspec-apply-change-subagent/SKILL.md)：OpenCode `@engineering-*` subagents。 |

## 结构

```text
herbertgao-skills/
├─ .claude-plugin/
│  └─ marketplace.json        # marketplace 清单
├─ review-loop/               # 一个 plugin（纯 skill）
│  ├─ .claude-plugin/
│  │  └─ plugin.json          # plugin 清单
│  └─ skills/
│     └─ review-loop/
│        └─ SKILL.md          # skill 本体（SOT）
├─ opsx/                      # Claude Code plugin（命令 + skill）
│  ├─ .claude-plugin/
│  │  └─ plugin.json
│  ├─ commands/
│  │  └─ apply-subagent.md
│  └─ skills/
│     └─ openspec-apply-change-subagent/
│        └─ SKILL.md
├─ codex-plugins/             # Codex plugin ports
│  ├─ review-loop/
│  │  ├─ .codex-plugin/
│  │  └─ skills/
│  └─ opsx/
│     ├─ .codex-plugin/
│     └─ skills/
├─ .agents/
│  └─ plugins/
│     └─ marketplace.json     # Codex repo-local marketplace
└─ .opencode/                 # OpenCode project/global-copyable ports
   ├─ commands/
   └─ skills/
```

Claude 原版新增 skill：在仓根加一个同构的 `<plugin>/` 目录，并在 `.claude-plugin/marketplace.json` 的 `plugins[]` 追加一条。

Codex 新增 skill：优先在 `codex-plugins/<plugin>/skills/<skill>/SKILL.md` 添加平台适配版，并在 `.agents/plugins/marketplace.json` 增加 marketplace entry。

OpenCode 新增 skill：在 `.opencode/skills/<skill>/SKILL.md` 添加平台适配版；需要 slash command 时放到 `.opencode/commands/`。

## Subagent 适配原则

- Claude Code：可以使用 Claude 的 `Agent tool` / `Task tool` / `subagent_type`。
- Codex：只使用 Codex subagent/custom agent；不使用 OpenCode `@` slugs，也不使用 Claude `subagent_type`。
- OpenCode：只使用 OpenCode `mode: subagent` agents 和 `@slug` 调用；不调用 Codex subagent，也不使用 `codex:codex-rescue`。

原 `review-loop` 的 Claude 版第三审查槽叫 Codex；Codex/OpenCode 适配版统一改成平台中立的 `Independent Reviewer`。

## License

MIT
