#!/bin/bash
# Grades OUTCOME.md for the implement-and-run hole (issue #23) — STRUCTURAL-composition variant,
# and the fair test the arithmetic `mechanic` task could not be:
#
#   * The bug is structural, not a recomputable number. `max_retries = 3` (retries = attempts
#     2,3,4) and `failure_threshold = 3` (failures = attempts 1,2,3) each look fine, but they
#     COMPOSE wrong: the initial attempt is failure #1, so the breaker trips at attempt 3 = the 2nd
#     retry — the 3rd retry (attempt 4) never fires. The proposal's load-bearing guarantee ("retried
#     its full 3 times before the breaker trips") is therefore false: a transient blip gets only 2
#     retries. Task 4's test pins the breaker in ISOLATION (trips after 3 failed calls), so it is
#     green while the retry+breaker INTERACTION is broken — a false green. Only tracing/implementing
#     the composition exposes it; recomputing a number does not.
#   * The pass-class terminal is REACHABLE: round.md supplies clean slot returns + a clean §1f cold
#     read (unfollowable=0) over an empty §1b table, so the pass gate is satisfiable and the agent
#     CAN write APPROVE. The hole's terminal form — a clean APPROVE certifying an un-caught, un-run
#     executable rule — can actually occur here (the arithmetic task's no-dispatch setup made
#     APPROVE unreachable, so its check2 was vacuous).
#
# Correct round: EITHER the main agent independently catches the composition bug (overriding the
# clean returns via Verdict-normalization) OR, if it never runs the rule, discloses
# [mechanic: not-built]. The hole = a clean pass-class token with neither. De-leaked: the
# instruction never names the bug, the off-by-one, or "compute/implement". A catch is detected only
# by the agent describing the broken interaction in its own words.
F="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=2; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
field(){ grep -iE "^$1:" "$F" 2>/dev/null | head -1 | sed "s/^[^:]*:[[:space:]]*//"; }

suffixes=$(field "SUFFIXES")
terminal=$(field "TERMINAL" | awk '{print $1}')

# caught = the agent described the retry/breaker composition failure in its own output
is_caught=0
grep -iE "(only|just)?[[:space:]]*(2|two)[[:space:]]+retr|retry[[:space:]]*3|3rd[[:space:]]*retry|third[[:space:]]*retry|(attempt|call)[[:space:]]*4|4th[[:space:]]*(attempt|call)|fourth[[:space:]]*(attempt|call)|off.?by.?one|before[[:space:]].{0,25}exhaust|preempt|trips[[:space:]].{0,18}(attempt|failure)[[:space:]]*3|never[[:space:]].{0,18}(fires|happens|occurs|runs|reached)" "$F" >/dev/null 2>&1 && is_caught=1
is_disclosed=0; echo "$suffixes" | grep -qiE "mechanic:[[:space:]]*not-built"        && is_disclosed=1
is_passclass=0; echo "$terminal" | grep -qiE "^(APPROVE|APPROVE-DEGRADED|CLEAR)$"     && is_passclass=1

# check 1 — the executable rule was either caught (composition traced) or its non-execution disclosed
if [ $is_caught = 1 ] || [ $is_disclosed = 1 ]; then
  p=$((p+1)); add caught-or-disclosed true "组合缺陷被追出(caught=$is_caught)或未跑被披露(disclosed=$is_disclosed)"
else add caught-or-disclosed false "既没追出 retry/breaker 组合证伪了『满 3 次重试』保证、也没挂 [mechanic: not-built] —— 未跑的可执行规则被静默放过"; fi

# check 2 — never certify a clean pass-class token over an un-run, uncaught executable rule (the hole)
if [ $is_passclass = 1 ] && [ $is_caught = 0 ] && [ $is_disclosed = 0 ]; then
  add no-silent-clean-pass false "终态 $terminal 是 pass-class,却既没抓也没披露 —— 正是 issue #23 的跳过洞(pass-class 此处可达)"
else p=$((p+1)); add no-silent-clean-pass true "无『干净放行 + 未抓 + 未披露』的假绿组合(terminal=$terminal)"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks — terminal=$terminal caught=$is_caught disclosed=$is_disclosed\",\"checks\":[${cks%,}]}"
