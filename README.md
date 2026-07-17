# herbertgao-skills

HerbertGao 的自托管 AI coding skills 仓库。三个对抗式质量控制 skill,一套源码两条分发线:Claude Code 走 plugin marketplace,其它平台走 `npx skills add` 装平台中立的通用版。

## 收录的 skill

| Skill | 做什么 | 何时用 |
| --- | --- | --- |
| **review-loop** | 对抗式 review 循环:三个跨家族 reviewer 并行撕产物 → 合并 triage → 最小化修复 → 重审到终态 | 已经写出来的东西要撕:OpenSpec 变更 / 提案 / spec / diff / 纯散文 |
| **council** | 多专家评议会:从 catalog 拉 4+ 真专家独立首轮 → 记 crux → 辩论 → 人类价值裁决 | 还没写任何产物的开放决策:选型 / 架构 / 要不要做 |
| **opsx** | 编排式实现 OpenSpec 变更:按范围分组 → 每组派 subagent → 主 agent 只做状态管理与 review | 用 subagent 分组方式实现 OpenSpec 任务 |

用序:先 `council` 定方向,再 `review-loop` 撕产物。`council` 有 canonical dispatch/return 记录时审计后可出 `CONVERGED`;只有 fresh-context 席位而缺记录时仍完成辩论,但只出不认证、不授权实现的 non-authorizing `ADVISORY`。

## 前置

| 依赖 | 谁需要 | 装法 | 缺了会怎样 |
| --- | --- | --- | --- |
| [agency-agents](https://github.com/msitarzewski/agency-agents) | 三个 skill 的专家/reviewer catalog(自己 clone、控制版本,skill 只读) | `git clone https://github.com/msitarzewski/agency-agents ~/.agency-agents` | review-loop / opsx 退到内嵌浓缩 prompt(专家更弱,终态封顶);council 凑不齐真专家就 `STOPPED` |
| [ponytail](https://github.com/DietrichGebert/ponytail) | 推荐,非必需(主 agent 的 YAGNI 精简纪律) | 见其 README(Claude Code / Codex 有包装);无插件机制的环境把 persona 粘进全局指令文件 | 主 agent 日常写码失去精简约束;skill 内部已内嵌该阶梯,不依赖它 |
| `openspec-cn` CLI | 仅 opsx | 自行安装(不附带) | opsx 无法运行 |

## 安装

### Claude Code — plugin marketplace

```text
/plugin marketplace add HerbertGao/herbertgao-skills
/plugin install review-loop@herbertgao-skills
/plugin install council@herbertgao-skills
/plugin install opsx@herbertgao-skills
```

更新:`/plugin marketplace update herbertgao-skills` 后重装。装过旧 marketplace 先 `/plugin marketplace remove claude-skills`。

### 其它平台(OpenCode / Codex / Trae / Cursor …)— `npx skills add`

```bash
npx skills add HerbertGao/herbertgao-skills --list          # 列出可装 skills
npx skills add HerbertGao/herbertgao-skills                 # 装到自动检测的 agent
npx skills add HerbertGao/herbertgao-skills --agent codex
```

Codex 亦可走原生 marketplace(`codex-plugins/` 下 SKILL.md 是通用版逐字节副本):

```bash
codex plugin marketplace add HerbertGao/herbertgao-skills --ref main
codex plugin add review-loop@herbertgao-skills-codex
codex plugin add council@herbertgao-skills-codex
codex plugin add opsx@herbertgao-skills-codex
```

## 通用版 vs plugin 版

一份逻辑、两种封装,差异只在宿主耦合点;共享的辩论、triage、终态语义两版对等。

| Skill | Claude Code plugin 版 | 通用版(npx) |
| --- | --- | --- |
| review-loop | `subagent_type` + Codex rescue lane | 第三审查槽换成平台中立的 `Independent Reviewer` |
| council | Claude 审计模式 + 能力不足降 advisory | 平台能力路由,按证据能力出 `CONVERGED` / `ADVISORY` |
| opsx | `general-purpose` subagent | 按 catalog 源路径 + 角色名解析 |

语言约定:`council` / `review-loop` 全线英文(避免中英孪生漂移);`opsx` 全线中文(配 openspec-cn)。

## 更多

- [调试 / 行为验证](./evals/SKILLGRADE.md) — 用 skillgrade 对 skill 做确定性行为 eval。
- [仓库结构与维护](./docs/maintaining.md) — 权威源(SOT)规则、契约校验、新增 skill 的清单。

## License

MIT
