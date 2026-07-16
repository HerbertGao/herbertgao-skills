# skillgrade 使用指南

本仓库用 [skillgrade](https://www.npmjs.com/package/skillgrade) 对 agent skill 做行为验证。每个 skill 在 `evals/<skill>/` 下有自己的 `eval.yaml`。

## 安装

无需全局安装，直接 `npx skillgrade` 即可。

## 运行

```bash
# 运行某个 skill 的全部 eval（默认 5 trials，threshold 0.8）
cd evals/council
npx skillgrade

# 运行单个 eval task
npx skillgrade --eval=advisory-routing

# 快速冒烟（1 trial）
npx skillgrade --eval=advisory-routing --trials=1

# CI 模式：低于 threshold 非零退出
npx skillgrade --eval=advisory-routing --ci --threshold=1.0
```

## Agent 选择

`eval.yaml` 的 `defaults.agent` 指定默认 agent。本仓库的 eval 需要能写文件（OUTCOME.md），因此不是所有 agent 都兼容。

| agent | 命令 | 能写文件 | 兼容性 |
|---|---|---|---|
| `command`（默认，走 `run-codex.sh`） | `codex exec --sandbox workspace-write` | ✓ | ✓ |
| `claude` | `claude -p --dangerously-skip-permissions` | ✓ | ✓ |
| `command` + trae-cli wrapper | `trae-cli -p` | ✗（print 模式只输出，不调 Write/Edit） | ✗ |
| `command` + agy wrapper | `agy --prompt --dangerously-skip-permissions` | ✓ | ✓ |

### 用不同 agent 跑

```bash
# codex（默认）
npx skillgrade --eval=advisory-routing --trials=1 --provider=local

# claude
npx skillgrade --eval=advisory-routing --trials=1 --provider=local --agent=claude

# trae-cli（不兼容写文件型 eval）
# trae-cli -p 是纯 print 模式，无法在 workspace 中创建 OUTCOME.md
# 需要写文件的 eval 不适用于 trae-cli

# agy（Google Antigravity CLI）
# agy --prompt 需要参数而非 stdin，用 wrapper 转换：
cat > /tmp/agy-skillgrade.sh << 'EOF'
#!/bin/bash
PROMPT=$(cat)
exec agy --prompt "$PROMPT" --dangerously-skip-permissions
EOF
chmod +x /tmp/agy-skillgrade.sh
npx skillgrade --eval=advisory-routing --trials=1 --provider=local \
  --agent=command --command="/tmp/agy-skillgrade.sh"
```

## Eval 结构

每个 `evals/<skill>/` 目录：

- `eval.yaml` — eval 配置（task 定义、workspace 文件映射、grader）
- `fixtures/` — 输入文件（SKILL.md、host-profiles.md、decision.md 等）
- `graders/` — 评分脚本（bash，输出 JSON）
- `bin/run-codex.sh` — codex agent 的启动脚本（做 HOME 隔离）

### Task 类型

1. **prereq-halt** — 验证前置条件缺失时正确 STOPPED（如 catalog 不存在）
2. **unfollowable-floor** — 冷读 SKILL.md，统计不可遵守的规则数（≤3）
3. **advisory-routing** — 给定 host profile，验证 Platform Adapter 的模式路由（audited / advisory / stopped）和 token 判定正确
4. **advisory-debate-shape** — 验证弱 provenance 下仍保留 opposing-only unopposed、DA、全席 cross-exam、DA-final、人类价值裁决与 minority report

### Grader

grader 是确定性 bash 脚本，对 `OUTCOME.md` 做逐行 exact match。支持通过 `OUTCOME_FILE` 环境变量指定输入文件（用于验证 grader 自身）：

```bash
# 用 valid fixture 验证 grader 能正确通过
OUTCOME_FILE=fixtures/advisory-routing-valid.md bash graders/advisory-routing.sh

# 用 false-green fixture 验证 grader 能抓住错误答案
OUTCOME_FILE=fixtures/advisory-routing-false-green.md bash graders/advisory-routing.sh
```

## 结果

结果写入 `$TMPDIR/skillgrade/<skill>/results/`，每个 trial 一个 JSON 文件，包含 session_log（命令、stdout/stderr、exitCode）和 grader_results。

查看最近一次结果：

```bash
ls -t $TMPDIR/skillgrade/council/results/*.json | head -1 | xargs cat | python3 -m json.tool
```

## 注意事项

- **必须 cd 到 `evals/<skill>/` 目录运行**，因为 `eval.yaml` 的 `skill:` 和 `workspace:` 路径是相对的
- codex agent 需要认证（`CODEX_HOME` 默认 `~/.codex`）
- claude agent 需要认证且未触发限额
- `advisory-routing` task 的 `threshold: 1.0`（要求 31/31 全对），`advisory-debate-shape` 要求 16/16，其他 task 默认 0.8
- Codex 在开发过程中可能频繁修改 SKILL.md 和 eval 文件；跑 eval 前确认 working tree 是预期状态
