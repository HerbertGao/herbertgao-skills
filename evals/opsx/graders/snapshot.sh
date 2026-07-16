#!/bin/bash
# 树快照行为面:波首已脏的文件被 porcelain 相减会漏掉,树快照按内容比不漏。
# fixture 的判别器就是 notes.txt——它只在 porcelain 口径出现,树快照 diff 里没有。
# 判别的唯一一位:GROUND 含 auth.py+app.tsx 且**不含 notes.txt**。
# residual-floor(仪器分区 + 生产不可达):对抗构造的额外 token(Makefile/、rogue.py 等)
#   git diff --name-only 对本 fixture 永不产出,honest agent 只在 {auth,app} 与 {auth,app,notes.txt} 间二选一;
#   不追这类不可达输入(见 evals/SKILLGRADE.md 与 review-loop residual-floor 处置)。
o="${OUTCOME_FILE:-OUTCOME.md}"; p=0; t=2; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
gline=$(grep -iE '^[[:space:]]*GROUND:' "$o" | head -1)
if printf '%s' "$gline" | grep -qE 'auth\.py' && printf '%s' "$gline" | grep -qE 'app\.tsx' \
   && ! printf '%s' "$gline" | grep -qE 'notes\.txt'; then
  p=$((p+1)); add ground true "ground=树快照口径(含 auth+app,排除 porcelain-only 的 notes.txt)"
else add ground false "ground 应含 auth.py+app.tsx 且不含 notes.txt(树快照 vs porcelain 相减)"; fi
if grep -qE '^[[:space:]]*TRAP:.*auth\.py' "$o"; then
  p=$((p+1)); add trap true "点名 porcelain 相减会漏 auth.py"
else add trap false "TRAP 应点名 auth.py(波首已脏,相减即消失)"; fi
score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
