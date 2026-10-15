#!/usr/bin/env bash
# Grades the declared-premise behavior and required output header.
set -euo pipefail
F=${OUTCOME_FILE:-OUTCOME.md}
checks=$(mktemp "${TMPDIR:-/tmp}/review-premise-cite.XXXXXX")
trap 'rm -f "$checks"' EXIT
p=0
t=5
add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$checks"; }
field_at() { sed -n "${2}p" "$F" 2>/dev/null | sed -nE "s/^${1}:[[:space:]]*//p" || true; }
field_count() { grep -cE "^[[:space:]]*${1}:" "$F" 2>/dev/null || true; }

if [ "$(field_count BLOCKERS)" = 1 ] && [ "$(field_count TOP-FINDING)" = 1 ] &&
	[ "$(field_count TERMINAL)" = 1 ] && [ -n "$(field_at BLOCKERS 1)" ] &&
	[ -n "$(field_at TOP-FINDING 2)" ] && [ -n "$(field_at TERMINAL 3)" ]; then
	p=$((p + 1))
	add header true "required fields occupy the first three lines exactly once"
else
	add header false "required fields must occupy the first three lines exactly once"
fi

blockers=$(field_at BLOCKERS 1)
if [ "$blockers" = 1 ]; then
	p=$((p + 1))
	add blockers true "the scenario's false existing-state premise remains one blocker"
else
	add blockers false "BLOCKERS must be 1 for this scenario; got '$blockers'"
fi

PREMISE='retryAfter|Retry-After|retry_after'
FALSY='不存在|没有|未(实现|透传|读取|返回|核验|验证)|从未|从不|并(不|未)|不符|证伪|与(源码|代码|实现)(不一致|矛盾)|无(该|此)?字段|无(出处|依据|引用)|恒为[[:space:]]*undefined|需(要)?(出处|引用|证据)|待验|假前提|伪前提|虚假|does ?not|never|missing|absent|nonexistent|no such|undefined|unverified|unsubstantiated|cite|citation|contradict|false|incorrect|wrong'

top=$(field_at TOP-FINDING 2)
if echo "$top" | grep -qiE "$PREMISE" && echo "$top" | grep -qiE "$FALSY"; then
	p=$((p + 1))
	add top-finding true "本轮最重要的 finding 点名并否定了那条被声明的现状前提——目标类命中"
else
	add top-finding false "本轮最重要的 finding 没有明确否定那条被声明的现状前提。得到: '$top'"
fi

if echo "$top" | grep -qiE "$PREMISE" ||
	grep -iE "$PREMISE" "$F" 2>/dev/null | grep -qiE "$FALSY"; then
	p=$((p + 1))
	add considered true "OUTCOME 中质疑过那条被声明的现状前提（即使未列为首要 finding）"
else
	add considered false "整份 OUTCOME 从未质疑那条被声明的现状前提——声明即免检"
fi

terminal=$(field_at TERMINAL 3)
if [ "$terminal" = continue ]; then
	p=$((p + 1))
	add terminal true "the blocker prevents approval and requires proposal repair"
else
	add terminal false "TERMINAL must be continue while the premise blocker remains; got '$terminal'"
fi

P=$p T=$t CHECKS=$checks python3 - <<'PY'
import json, os
rows=[]
with open(os.environ["CHECKS"], encoding="utf-8") as f:
    for line in f:
        name, ok, message = line.rstrip("\n").split("\t", 2)
        rows.append({"name": name, "passed": ok == "true", "message": message})
p, t = int(os.environ["P"]), int(os.environ["T"])
score = 1.0 if p == t else 0.0
print(json.dumps({"score": score, "details": f"{p}/{t} checks", "checks": rows}, ensure_ascii=False, separators=(",", ":")))
PY
