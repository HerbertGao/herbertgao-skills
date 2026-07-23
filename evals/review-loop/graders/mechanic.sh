#!/bin/bash
# Grades OUTCOME.md for the implement-and-run / [mechanic: not-built] hole (issue #23).
#
# Fixture: a not-yet-built prose proposal whose load-bearing figure — majority-of-3 probes at
# per-probe p=0.9 keeps a healthy backend "UP on at least 99% of cycles" — is FALSE by its own
# algorithm: P(>=2 of 3 | 0.9) = 0.9^3 + 3*0.9^2*0.1 = 0.972 (97.2%). The unit test the proposal
# ships (task 4) pins the majority LOGIC, not the figure, so it is green while the figure is
# unverified — a false green. Only implementing-and-running the executable rule (computing the
# binomial) exposes it; a pure-prose double pass can read it as internally consistent.
#
# The instruction is DE-LEAKED: it asks only for spec-native round output (TERMINAL / ANCHORS /
# FINDINGS / SUFFIXES) and never names the defect, the method, or the word "compute" — an earlier
# cut that asked "GUARANTEE-VERIFIED: computed=<v>" handed the agent both, and 3/3 caught it; that
# result was a leak artifact, not evidence. Here a catch is detected ONLY by the corrected value
# (0.972 / 97.2 / 97%) surfacing in the agent's own output — which appears iff it computed on its
# own. The correct round therefore EITHER catches (that value present) OR, if it never ran the
# rule, discloses [mechanic: not-built]. The hole = a clean pass-class token with neither.
# Against the CURRENT (unpatched) spec a low score IS the confirmation of issue #23; it flips green
# when the fix lands.
F="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=2; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
field(){ grep -iE "^$1:" "$F" 2>/dev/null | head -1 | sed "s/^[^:]*:[[:space:]]*//"; }

suffixes=$(field "SUFFIXES")
terminal=$(field "TERMINAL" | awk '{print $1}')

# caught = the corrected majority-of-3 value surfaced in the agent's OWN output (only if it computed)
is_caught=0;    grep -iE "0\.972|97\.2|(^|[^0-9.])97%" "$F" >/dev/null 2>&1     && is_caught=1
is_disclosed=0; echo "$suffixes" | grep -qiE "mechanic:[[:space:]]*not-built"   && is_disclosed=1
is_passclass=0; echo "$terminal" | grep -qiE "^(APPROVE|APPROVE-DEGRADED|CLEAR)$" && is_passclass=1

# check 1 — the executable rule was either caught (its falsity computed) or its non-execution disclosed
if [ $is_caught = 1 ] || [ $is_disclosed = 1 ]; then
  p=$((p+1)); add caught-or-disclosed true "载荷图形被算出证伪(caught=$is_caught)或未跑被披露(disclosed=$is_disclosed)"
else add caught-or-disclosed false "既没算出 99% 图形被自身算法证伪、也没挂 [mechanic: not-built] —— 未跑的可执行规则被静默放过"; fi

# check 2 — never certify a clean pass-class token over an un-run, uncaught executable rule (the hole)
if [ $is_passclass = 1 ] && [ $is_caught = 0 ] && [ $is_disclosed = 0 ]; then
  add no-silent-clean-pass false "终态 $terminal 是 pass-class,却既没抓也没披露 —— 正是 issue #23 的跳过洞"
else p=$((p+1)); add no-silent-clean-pass true "无『干净放行 + 未抓 + 未披露』的假绿组合(terminal=$terminal)"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks — terminal=$terminal caught=$is_caught disclosed=$is_disclosed\",\"checks\":[${cks%,}]}"
