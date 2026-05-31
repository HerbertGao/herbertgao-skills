# claude-skills

HerbertGao 的自托管 Claude Code skills marketplace。集中管理自建 skill，避免散落丢失，并支持任意机器一键安装/更新。

## 安装

```text
/plugin marketplace add HerbertGao/claude-skills
/plugin install review-loop@claude-skills
/plugin install opsx@claude-skills
```

更新：`/plugin marketplace update claude-skills` 后重装对应 plugin。

> 注：`opsx` 需要 `openspec-cn` CLI（plugin 不附带，请自行安装）。若你此前已在 `~/.claude` 手动放过同名 command/skill，安装本 plugin 会产生重复，二选一即可。

## 收录的 skill

| Plugin | 说明 |
| --- | --- |
| [`review-loop`](./review-loop/skills/review-loop/SKILL.md) | 对本次提案与代码变更跑对抗性 review 自动循环：Codex + Code Reviewer + Reality Checker 三方并行 → 合并去重 triage → 派 Minimal Change Engineer 修复 → 重新 review，直到放行（APPROVE/CLEAR；Codex 结构性未跑完时 APPROVE-DEGRADED）或到可配置轮数上限。常配合内置 `/goal` 长跑。 |
| [`opsx`](./opsx/skills/openspec-apply-change-subagent/SKILL.md) | 以编排模式实现 OpenSpec 变更：主 agent 按范围（子项目 / 模块 / 技术栈）分组待处理任务，先并行后串行派发 subagent 开发，自己只跑 `openspec-cn` 状态管理与 review，不亲自写实现代码。提供 `/opsx:apply-subagent` 命令 + 其 SOT skill。需要 `openspec-cn` CLI。 |

## 结构

```text
claude-skills/
├─ .claude-plugin/
│  └─ marketplace.json        # marketplace 清单
├─ review-loop/               # 一个 plugin（纯 skill）
│  ├─ .claude-plugin/
│  │  └─ plugin.json          # plugin 清单
│  └─ skills/
│     └─ review-loop/
│        └─ SKILL.md          # skill 本体（SOT）
└─ opsx/                      # 一个 plugin（命令 + skill）
   ├─ .claude-plugin/
   │  └─ plugin.json          # plugin 清单
   ├─ commands/
   │  └─ apply-subagent.md    # /opsx:apply-subagent 薄命令
   └─ skills/
      └─ openspec-apply-change-subagent/
         └─ SKILL.md          # skill 本体（SOT）
```

新增 skill：在仓根加一个同构的 `<plugin>/` 目录，并在 `.claude-plugin/marketplace.json` 的 `plugins[]` 追加一条。

## License

MIT
