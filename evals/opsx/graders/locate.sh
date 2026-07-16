#!/bin/bash
# 定位链行为面:按 CLI description 定位复选框(容忍 subagent task 文本漂移)。
o="${OUTCOME_FILE:-OUTCOME.md}"; p=0; t=2; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
# taskId "2":CLI description="1.2 补充单元测试" 唯一命中第 3 行;subagent 漂移文本不影响
if grep -qE '^[[:space:]]*TASK-2:[[:space:]]*line[[:space:]]*3[[:space:]]*$' "$o"; then
  p=$((p+1)); add t2 true "taskId 2 按 CLI description 定位到第 3 行"
else add t2 false "taskId 2 应定位 line 3(用 CLI description,勿用 subagent 漂移文本)"; fi
# taskId "3":description="2.1 补充单元测试" 唯一命中第 5 行(含节号故唯一);若模型以"补充单元测试"模糊匹配会双命中→halt 也算对?
# 契约:description 是整行文本,"2.1 补充单元测试"唯一命中 line 5。
if grep -qE '^[[:space:]]*TASK-3:[[:space:]]*line[[:space:]]*5[[:space:]]*$' "$o"; then
  p=$((p+1)); add t3 true "taskId 3 定位 line 5"
else add t3 false "taskId 3 应定位 line 5"; fi
score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
