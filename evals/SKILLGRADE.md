# skillgrade 使用指南

本仓库用 [skillgrade](https://www.npmjs.com/package/skillgrade) 对 agent skill 做行为验证。每个 skill 在 `evals/<skill>/` 下有自己的 `eval.yaml`。

现有 eval 位于 `council`、`opsx` 与 `review-loop`。默认测试矩阵优先覆盖 Codex 和 Pi；每套 grader 都带 `graders/self-test.sh`（fixture + 假绿探针，改 grader 前先跑）。

## 安装

无需全局安装，直接 `npx skillgrade` 即可。

## 运行

```bash
# 运行某个 skill 的全部 eval（默认 5 trials，threshold 0.8）
cd evals/council
npx skillgrade

# 运行单个 eval task
npx skillgrade --eval=incumbent-routing

# 快速冒烟（1 trial）
npx skillgrade --eval=incumbent-routing --trials=1

# CI 模式：低于 threshold 非零退出
npx skillgrade --eval=incumbent-routing --ci --threshold=1.0
```

## Agent 选择

`eval.yaml` 的 `defaults.agent` 指定默认 agent。本仓库的 eval 需要能写文件（OUTCOME.md），因此不是所有 agent 都兼容。

| agent | 命令 | 能写文件 | 优先级 |
| --- | --- | --- | --- |
| `command` + Codex wrapper | `codex exec --sandbox workspace-write` | ✓ | 主测试宿主 |
| `command` + Pi wrapper | `pi --print --no-session` | ✓ | 主测试宿主 |
| `claude` | `claude -p --dangerously-skip-permissions` | ✓ | 可选兼容性复测 |
| `command` + trae-cli wrapper | `trae-cli -p` | ✗ | 不兼容写文件型 eval |
| `command` + agy wrapper | `agy --prompt --dangerously-skip-permissions` | ✓ | 可选 |

### 用不同 agent 跑

```bash
# Codex（该 task 的默认宿主）
npx skillgrade --eval=incumbent-routing --trials=1 --provider=local

# Pi（可覆盖任意 task；从当前 Pi 配置读取认证和默认模型）
npx skillgrade --eval=incumbent-routing --trials=1 --provider=local \
  --agent=command --command="bash bin/run-pi.sh"

# 可选：固定 Pi provider / model / thinking，便于复现实验
PI_EVAL_PROVIDER=openai PI_EVAL_MODEL=gpt-5.4 PI_EVAL_THINKING=high \
  npx skillgrade --eval=incumbent-routing --trials=1 --provider=local \
  --agent=command --command="bash bin/run-pi.sh"

# Claude 只保留为有可用账号时的兼容性复测，不属于默认矩阵
npx skillgrade --eval=incumbent-routing --trials=1 --provider=local \
  --agent=claude

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
npx skillgrade --eval=incumbent-routing --trials=1 --provider=local \
  --agent=command --command="/tmp/agy-skillgrade.sh"
```

## Eval 结构

每个 `evals/<skill>/` 目录：

- `eval.yaml` — eval 配置（task 定义、workspace 文件映射、grader）
- `fixtures/` — 输入文件（SKILL.md、场景和被审样本）
- `graders/` — 评分脚本（bash，输出 JSON）
- `bin/run-codex.sh` — Codex 启动脚本（做 HOME 隔离）
- `bin/run-pi.sh` — Pi 启动脚本（保留认证，隔离 HOME，并禁用外部资源）

### Task 类型

各 skill 的任务以自己的 `eval.yaml` 为准：

- **review-loop**：`expert-selection`、`knob-yagni`、`premise-cite`、`portable-routing`、`root-cause-escalation`、`output-retention`。路由档和记录表不再是被测行为。Bundled redactor 另有 runtime self-test，但不再是通过前置。
- **council**：`unfollowable-floor`、`incumbent-routing`、`trust-execution-boundary`。保证 mode 和组席停机报表已从通用版删除。
- **opsx**：分组、前置、reconcile、checkbox 定位与 snapshot 回归。

review-loop 旧三席、strong-anchor、cold-reader/simplicity 常驻 lane、confidentiality hard-stop 与 16 条 completion predicate 任务已随重协议废弃；删除原因见 `evals/review-loop/GRADERS.md`。

### Grader

grader 是确定性 bash 脚本：协议题逐行精确核对，效果题核对完整必填首部与目标语义；任一必填检查失败即整题 0 分。支持通过 `OUTCOME_FILE` 环境变量指定输入文件（用于验证 grader 自身）。skillgrade 0.2.2 会把 grader 复制进 trial，因此 review-loop 的 agent wrapper 会在模型运行期间隐藏所有含答案的评测脚手架，退出后恢复给 grader：

```bash
# 用 valid fixture 验证 grader 能正确通过
OUTCOME_FILE=fixtures/incumbent-routing-valid.md bash graders/incumbent-routing.sh

# 用 false-green fixture 验证 grader 能抓住错误答案
OUTCOME_FILE=fixtures/incumbent-routing-false-green.md bash graders/incumbent-routing.sh
```

## 结果

结果写入 `$TMPDIR/skillgrade/<skill>/results/`，每个 trial 一个 JSON 文件，包含 session_log（命令、stdout/stderr、exitCode）和 grader_results。

查看最近一次结果：

```bash
ls -t $TMPDIR/skillgrade/council/results/*.json | head -1 | xargs cat | python3 -m json.tool
```

## 注意事项

- **必须 cd 到 `evals/<skill>/` 目录运行**，因为 `eval.yaml` 的 `skill:` 和 `workspace:` 路径是相对的
- Codex agent 需要认证（`CODEX_HOME` 默认 `~/.codex`）
- Pi agent 需要在 `PI_CODING_AGENT_DIR`（默认 `~/.pi/agent`）中已有认证；wrapper 默认使用 `high` thinking，并禁用 context、extensions、skills 与 prompt templates，避免用户配置污染 eval
- Claude 不再是默认测试依赖；仅在显式兼容性复测时需要认证
- `incumbent-routing` 与 `trust-execution-boundary` 使用 `threshold: 1.0`，协议字段必须全对
- Codex 在开发过程中可能频繁修改 SKILL.md 和 eval 文件；跑 eval 前确认 working tree 是预期状态
