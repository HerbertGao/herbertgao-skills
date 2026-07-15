#!/bin/bash
# Grades OUTCOME.md for #9's acceptance: a §1f cold read of skills/council/SKILL.md must find
# unfollowable ≤ 3 (a rule that honestly labels itself a judgment / disclosed floor is followable,
# so it does NOT count). Baseline before the rewrite was ~11–18; post-rewrite trials ran 0,0,1.
# The count is stochastic — this is one trial; eval.yaml runs trials:5 / threshold:0.8.
p=0; t=1; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

n=$(grep -iE "unfollowable[[:space:]]*=[[:space:]]*[0-9]+" OUTCOME.md 2>/dev/null | grep -oE "[0-9]+" | tail -1)
if [ -n "$n" ] && [ "$n" -le 3 ]; then
  p=$((p+1)); add floor true "unfollowable = $n ≤ 3（写作模式重写达标）"
else
  add floor false "unfollowable = ${n:-?} > 3（或 OUTCOME 缺 COUNT 行）"
fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
