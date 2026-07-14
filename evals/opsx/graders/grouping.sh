#!/bin/bash
# Grades GROUPS.md: every task exactly once, write-sets declared, waves planned, nothing dispatched.
p=0; t=5; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

if test -f GROUPS.md && grep -q "任务分组" GROUPS.md; then p=$((p+1)); add fmt true "GROUPS.md 存在且含分组标题"
else add fmt false "GROUPS.md 缺失或无分组标题"; fi

# every task id 1..10 appears exactly once in group lines (lines carrying 任务)
miss=""; dup=""
for i in $(seq 1 10); do
  n=$(grep -E "^- \*\*组" GROUPS.md 2>/dev/null | grep -oE "任务[：: ][0-9, ]+" | grep -oE "\b$i\b" | wc -l | tr -d ' ')
  n=${n:-0}; [ "$n" -eq 0 ] && miss="$miss $i"; [ "$n" -gt 1 ] && dup="$dup $i"
done
if [ -z "$miss$dup" ]; then p=$((p+1)); add coverage true "任务 1-10 各出现一次"
else add coverage false "缺:$miss 重复:$dup"; fi

if [ "$(grep -cE '^- \*\*组.*写集' GROUPS.md 2>/dev/null)" -ge 2 ]; then p=$((p+1)); add writeset true "每组声明写集"
else add writeset false "写集声明不足"; fi

if grep -q "波次" GROUPS.md 2>/dev/null; then p=$((p+1)); add waves true "有波次计划"
else add waves false "无波次计划"; fi

if ! grep -q "\- \[x\]" openspec/changes/demo-pagination/tasks.md 2>/dev/null; then p=$((p+1)); add stop true "复选框未动（未越过步骤4）"
else add stop false "复选框被修改——越界执行"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
