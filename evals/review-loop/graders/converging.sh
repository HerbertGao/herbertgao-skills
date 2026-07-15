#!/bin/bash
# Grades OUTCOME.md for the converging-with-regressions Termination exception (#14).
# CASE A: count strictly drops AND no requirement recurs -> must CONTINUE (not NOT-CONVERGED).
# CASE B: count drops too, but a requirement recurs -> must fire NOT-CONVERGED.
# The discriminator is requirement-recurrence read from prose (no native IDs), which is the
# whole point: a count-only reading would continue on both.
p=0; t=2; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

if grep -qiE "^CASE-A-VERDICT:.*continue" OUTCOME.md 2>/dev/null && ! grep -qiE "^CASE-A-VERDICT:.*NOT-CONVERGED" OUTCOME.md 2>/dev/null; then
  p=$((p+1)); add caseA true "CASE A 续跑（converging-with-regressions），未误触 NOT-CONVERGED"
else add caseA false "CASE A 应续跑却判了 NOT-CONVERGED（或格式缺失）"; fi

if grep -qiE "^CASE-B-VERDICT:.*NOT-CONVERGED" OUTCOME.md 2>/dev/null; then
  p=$((p+1)); add caseB true "CASE B 正确 fire NOT-CONVERGED（认出散文里改头换面的 requirement 复发）"
else add caseB false "CASE B 漏判——计数下降就放过，未抓到 requirement 复发"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
