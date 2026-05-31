# claude-skills

HerbertGao 的自托管 Claude Code skills marketplace。集中管理自建 skill，避免散落丢失，并支持任意机器一键安装/更新。

## 安装

```text
/plugin marketplace add HerbertGao/claude-skills
/plugin install review-loop@claude-skills
```

更新：`/plugin marketplace update claude-skills` 后重装对应 plugin。

## 收录的 skill

| Plugin | 说明 |
| --- | --- |
| [`review-loop`](./review-loop/skills/review-loop/SKILL.md) | 对本次提案与代码变更跑对抗性 review 自动循环：Codex + Code Reviewer + Reality Checker 三方并行 → 合并去重 triage → 派 Minimal Change Engineer 修复 → 重新 review，直到放行（APPROVE/CLEAR；Codex 结构性未跑完时 APPROVE-DEGRADED）或到可配置轮数上限。常配合内置 `/goal` 长跑。 |

## 结构

```text
claude-skills/
├─ .claude-plugin/
│  └─ marketplace.json        # marketplace 清单
└─ review-loop/               # 一个 plugin
   ├─ .claude-plugin/
   │  └─ plugin.json          # plugin 清单
   └─ skills/
      └─ review-loop/
         └─ SKILL.md          # skill 本体（SOT）
```

新增 skill：在仓根加一个同构的 `<plugin>/` 目录，并在 `.claude-plugin/marketplace.json` 的 `plugins[]` 追加一条。

## License

MIT
