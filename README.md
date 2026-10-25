# herbertgao-skills

HerbertGao 的自托管 AI coding skills 仓库。五个可移植 workflow skill，一套源码两条分发线：Claude Code 走 plugin marketplace，其它平台走 `npx skills add` 装平台中立的通用版。

## 收录的 skill

| Skill | 做什么 | 何时用 |
| --- | --- | --- |
| **review-loop** | 找人挑错，改完再审，直到通过或明确卡点 | 已有方案、文档或代码，需要找问题并修好 |
| **council** | 让多位不同专家先各自判断，再讨论分歧并给出建议 | 面临技术或架构选择，不确定该走哪条路 |
| **opsx** | 把 OpenSpec 任务分组交给多个 subagent，主 agent 负责协调和验收 | 想让多个 subagent 分工完成 OpenSpec 任务 |
| **eli5** | 用大图和少量文字生成一个可离线分享的 HTML 概念解释器 | 想让新人快速理解技术概念、代码路径、Agent、MCP 或协议 |
| **journey-review** | 操作真实应用，按业务后置条件审查完整用户旅程 | 验证跨步骤任务、异常恢复，以及代码和单测无法证明的产品行为 |

`eli5` 是独立的学习/分享工具。交付用序：先 `council` 定方向，再 `review-loop` 撕产物；实现后可用 `journey-review` 验证完整任务。审查范围需要真实业务证据且环境可安全运行时，`review-loop` 也可自主调用 `journey-review`；这不是所有审查的强制步骤。两份 council 正文一致。结果是决策，does not certify；实现留到之后的明确指令。

路由按**终点**而不是“有没有文档”判断：

| 输入与期望终点 | 使用方式 |
| --- | --- |
| 没有草稿，要选择架构 / 技术 | `council`，从零选择 |
| 已有架构草稿，要比较后决定保留 / 替换 / 组合 / 未决 | `council` incumbent-draft mode（不修改草稿） |
| 已有工件，要找错、修复并迭代到 `APPROVE` | `review-loop` |
| 既要选架构又要改稿 | 先 `council`；方向未决则停，已决后再交给 `review-loop` |
| 已实现功能，要验证真实用户任务和业务最终状态 | `journey-review`；不以代码审查或测试通过代替真实执行 |

## 前置

| 依赖 | 谁需要 | 装法 | 缺了会怎样 |
| --- | --- | --- | --- |
| [agency-agents](https://github.com/msitarzewski/agency-agents) | review-loop / council / opsx 的专家/reviewer catalog（自己 clone、控制版本，skill 只读） | `git clone https://github.com/msitarzewski/agency-agents ~/.agency-agents` | review-loop 的 CR/RC 用内嵌角色、跳过可选领域专家并继续；opsx 按自身规则；council 缺 catalog 也继续并给出结论；eli5 / journey-review 不需要 |
| [ponytail](https://github.com/DietrichGebert/ponytail) | 推荐,非必需(主 agent 的 YAGNI 精简纪律) | 见其 README；无插件机制的环境把 persona 粘进全局指令文件 | 主 agent 日常写码失去精简约束；review-loop 已在 CR 与修复规则中内嵌必要的最小实现阶梯，不依赖它 |
| `openspec-cn` CLI | 仅 opsx | 自行安装(不附带) | opsx 无法运行 |

## 安装

### Claude Code — plugin marketplace

```text
/plugin marketplace add HerbertGao/herbertgao-skills
/plugin install review-loop@herbertgao-skills
/plugin install council@herbertgao-skills
/plugin install opsx@herbertgao-skills
/plugin install eli5@herbertgao-skills
/plugin install journey-review@herbertgao-skills
```

更新:`/plugin marketplace update herbertgao-skills` 后重装。装过旧 marketplace 先 `/plugin marketplace remove claude-skills`。

### 其它平台（OpenCode / Trae / Cursor …）— `npx skills add`

```bash
npx skills add HerbertGao/herbertgao-skills --list          # 列出可装 skills
npx skills add HerbertGao/herbertgao-skills                 # 装到自动检测的 agent
```

## 通用版 vs plugin 版

一份正文、两种封装。Claude plugin 与通用版的 `SKILL.md` 字节一致，不再保留宿主专用分支。

| Skill | Claude Code plugin 版 | 通用版(npx) |
| --- | --- | --- |
| review-loop | 与通用版同一份正文 | 先审、再小改、再复审；没有专用 subagent 也能继续 |
| council | 与通用版同一份正文 | 讨论后直接给出可行结论；does not certify |
| opsx | 与通用版同一份正文 | 按任务需要选择专家并分工 |
| eli5 | 与通用版字节一致；生成单文件 HTML | 同一 host-neutral 工作流 |
| journey-review | 与通用版字节一致；真实旅程与后置条件审查 | 同一 host-neutral 工作流，无独立执行环境时返回 `JOURNEY-BLOCKED` |

语言约定：`council` / `review-loop` / `eli5` / `journey-review` 全线英文（避免孪生漂移）；`opsx` 全线中文（配 openspec-cn）。

## 维护约束

修改任何 `SKILL.md` 的 frontmatter `description` 时，解析后的描述必须不超过 **1024 个字符**（建议控制在 900 字符以内以保留余量），并同步检查通用版、Claude plugin 版及已安装副本，避免宿主报告 `description exceeds 1024 characters`。

## 更多

- [调试 / 行为验证](./evals/SKILLGRADE.md) — 用 skillgrade 对 skill 做确定性行为 eval。
- [仓库结构与维护](./docs/maintaining.md) — 权威源(SOT)规则、契约校验、新增 skill 的清单。

## Upstream attribution

`eli5` 是对 Anthropic community marketplace ELI5 Skill 的 portable adaptation，原作者为 Thariq Shihipar。固定上游来源与 MIT notice 见 [`skills/eli5/LICENSE.upstream`](./skills/eli5/LICENSE.upstream)。

## License

MIT
