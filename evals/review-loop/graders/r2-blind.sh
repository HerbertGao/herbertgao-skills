#!/bin/bash
# Grades OUTCOME.md for the round-2 regression blind spot claimed in issue #22 item 2.
# Fixture: round 1 is the loop's first round; round 2's triage is 3 blocker/major, ALL of them
# fix-induced under the prose test (each quotes text round 1 Landed AND names a requirement that
# did not exist before that rewrite). What the spec makes determinate:
#   1. Regression: is `3 of 3` — the ratio IS echoed, so "no mechanism makes it visible" is false;
#   2. the root-cause step is NOT dispatched at round 2 (its trigger needs two consecutive rounds);
#   3. round 2 therefore writes no token and continues;
#   4. with round 1 forced to `n/a (no prior fix)`, the earliest NOT-CONVERGED is round 3.
# 1 vs 2+3+4 is the whole question: visible but ungated, or invisible.
F="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=4; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
field(){ grep -iE "^$1:" "$F" 2>/dev/null | head -1 | sed "s/^[^:]*:[[:space:]]*//"; }

r=$(field "R2-REGRESSION")
if echo "$r" | grep -qiE "^3[[:space:]]+of[[:space:]]+3"; then
  p=$((p+1)); add ratio true "Regression: 3 of 3 —— 单轮修复缺陷率在状态块上是可见的"
else add ratio false "Regression 比值算错（应 3 of 3，得到: '$r'）—— 三条全部满足散文 fix-induced 双条件"; fi

rc=$(field "R2-ROOT-CAUSE-DISPATCHED")
if echo "$rc" | grep -qiE "^no"; then
  p=$((p+1)); add rootcause true "R2 不派根因分析师 —— 触发器要连续两轮，R1 恒为 n/a"
else add rootcause false "R2 就派了根因分析师 —— 与 Termination 的两轮触发器不符（得到: '$rc'）"; fi

term=$(field "R2-TERMINAL")
if echo "$term" | grep -qiE "^continue"; then
  p=$((p+1)); add terminal true "R2 无 token，续跑"
else add terminal false "R2 写了终态 token（应 continue，得到: '$term'）"; fi

e=$(field "EARLIEST-NOT-CONVERGED-ROUND" | grep -oE "[0-9]+" | head -1)
if [ "${e:-0}" = "3" ]; then
  p=$((p+1)); add earliest true "最早点火轮次 = 3（R1 的 n/a 吃掉了第一轮）"
else add earliest false "最早点火轮次算错（应 3，得到: '${e:-空}'）"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
