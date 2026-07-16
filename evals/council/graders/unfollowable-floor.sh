#!/bin/bash
# A §1f cold read of skills/council/SKILL.md must find unfollowable ≤ 3 (a rule that honestly
# labels itself a judgment / disclosed floor is followable, so it does NOT count).
# Un-rewritten baseline is ~11–18 vs ~0–1 after the writing-mode rewrite — the threshold is a
# regression line. The count is stochastic — one trial here; eval.yaml runs trials:5 / threshold:0.8.
o="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=1; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

# 闭式判定，两个检查共用同一宽松前缀，不给第三个模式留缝：
#   a) 全文只允许一处 COUNT 提及（宽松、大小写不敏感、不锚行首 —— 严格一条+改口一条、大小写变体双写、
#      行中/引用块里的第二次自报都死在这里）；
#   b) 最后一个非空行必须整行严格匹配（大小写敏感 —— 指令要求「严格写」），n 只从这一行取。
# 地板（披露）：n 本身是自报数，bash grader 无法对照上文 findings 复核 —— 这由 trials:5 的分布回归兜底。
last=$(grep -vE '^[[:space:]]*$' "$o" 2>/dev/null | tail -1)
loose=$(grep -ciE 'count[[:space:]]*:[[:space:]]*unfollowable' "$o" 2>/dev/null)
n=$(printf '%s' "$last" | grep -oE '^COUNT: unfollowable = [0-9]+[[:space:]]*$' | grep -oE '[0-9]+' | head -1)
if [ "${loose:-0}" -eq 1 ] && [ -n "$n" ] && [ "$n" -le 3 ]; then
  p=$((p+1)); add floor true "unfollowable = $n ≤ 3（写作模式重写达标）"
else
  add floor false "unfollowable = ${n:-?}（需 ≤3、COUNT 行全文唯一且最后一个非空行整行严格匹配；实际 COUNT 前缀行数=${loose:-0}）"
fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
