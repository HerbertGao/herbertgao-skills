#!/bin/bash
cd "$(dirname "$0")/.." || exit 1
G=graders; pass=0; fail=0
score(){ python3 -c "import json,sys; print(json.load(sys.stdin)['score'])"; }
run(){ local d; d=$(mktemp -d); printf '%s\n' "$4" > "$d/O.md"
  local s; s=$(OUTCOME_FILE="$d/O.md" bash "$G/$2" 2>/dev/null | score)
  local ok; if [ "$3" = pass ]; then ok=$(python3 -c "print(1 if $s>=0.99 else 0)"); else ok=$(python3 -c "print(1 if $s<0.99 else 0)"); fi
  if [ "$ok" = 1 ]; then pass=$((pass+1)); echo "  ✅ $1 ($s/$3)"; else fail=$((fail+1)); echo "  ❌ $1 ($s want $3)"; fi
}
echo "== reconcile =="
run "valid: halt+点名" reconcile.sh pass 'CHECK-RECONCILE: fail
test_users.py 申报了但 ground 里没有
VERDICT: halt'
run "假绿: 标记通过" reconcile.sh reject 'CHECK-RECONCILE: pass
VERDICT: mark'
run "漏点名" reconcile.sh reject 'CHECK-RECONCILE: fail
VERDICT: halt'
run "假绿:failure/halted子串" reconcile.sh reject 'CHECK-RECONCILE: failure
test_users.py
VERDICT: halted'
run "假绿A2:fail只在散文" reconcile.sh reject 'CHECK-RECONCILE: pass
（若反向对账为 fail 则 halt）
VERDICT: halt'
run "中文标记绕过(A3)" reconcile.sh reject 'CHECK-RECONCILE: fail — test_users.py 声称改了没改
已标记任务 1
VERDICT: halt'
echo "== locate =="
run "valid" locate.sh pass 'TASK-2: line 3
TASK-3: line 5'
run "假绿: 定位到已勾选行" locate.sh reject 'TASK-2: line 2
TASK-3: line 5'
echo "== snapshot =="
run "valid" snapshot.sh pass 'GROUND: backend/auth.py, frontend/app.tsx
TRAP: backend/auth.py — 波首已脏,porcelain 相减后从 ground 消失'
run "假绿: 相减口径漏 auth" snapshot.sh reject 'GROUND: frontend/app.tsx
TRAP: 无'
run "假绿S1:超集裸porcelain" snapshot.sh reject 'GROUND: backend/auth.py, frontend/app.tsx, notes.txt
TRAP: backend/auth.py'
echo; echo "self-test: $pass passed, $fail failed"; [ "$fail" -eq 0 ]
