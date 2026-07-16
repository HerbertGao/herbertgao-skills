#!/bin/bash
# 步骤 6 四道校验的行为面:反向对账(⋃filesChanged ∖ ground)必须抓住"申报了没改"的假绿并 halt。
o="${OUTCOME_FILE:-OUTCOME.md}"; p=0; t=3; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
# ① 反向对账判负:必须点名 test_users.py(申报了、ground 里没有)
if grep -qE 'test_users\.py' "$o" && grep -qiE '^[[:space:]]*CHECK-RECONCILE:[[:space:]]*fail[[:space:]]*$' "$o" && ! grep -qiE '^[[:space:]]*CHECK-RECONCILE:[[:space:]]*pass[[:space:]]*$' "$o"; then
  p=$((p+1)); add reverse true "反向对账抓住了申报未改"
else add reverse false "没抓住 filesChanged∖ground 的 test_users.py"; fi
# ② VERDICT 必须 halt,不得标记
if grep -qiE '^[[:space:]]*VERDICT:[[:space:]]*halt[[:space:]]*$' "$o" && ! grep -qiE '^[[:space:]]*VERDICT:[[:space:]]*mark[[:space:]]*$' "$o"; then
  p=$((p+1)); add verdict true "halt 而非标记"
else add verdict false "应 halt(校验②不过 ⇒ 该组不得标记)"; fi
# ③ 不得把 taskId 1/2 标成完成(covered by verdict,但显式防"部分标记")
if ! grep -qiE '^[[:space:]]*MARK(ED)?:.*(taskId )?[12]\b' "$o" && ! grep -qE '(已标记|标记了).*任务.*[12]' "$o"; then
  p=$((p+1)); add nomark true "未标记任何任务"
else add nomark false "校验不过却标记了任务"; fi
score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
