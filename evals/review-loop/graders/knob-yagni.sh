#!/usr/bin/env bash
# Grades the YAGNI target behavior and required output header.
set -euo pipefail
F=${OUTCOME_FILE:-OUTCOME.md}
checks=$(mktemp "${TMPDIR:-/tmp}/review-knob-yagni.XXXXXX")
trap 'rm -f "$checks"' EXIT
p=0
t=5
add() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$checks"; }
field_at() { sed -n "${2}p" "$F" 2>/dev/null | sed -nE "s/^${1}:[[:space:]]*//p" || true; }
field_count() { grep -cE "^[[:space:]]*${1}:" "$F" 2>/dev/null || true; }

if [ "$(field_count BLOCKERS)" = 1 ] && [ "$(field_count TOP-FIX)" = 1 ] &&
	[ "$(field_count TERMINAL)" = 1 ] && [ -n "$(field_at BLOCKERS 1)" ] &&
	[ -n "$(field_at TOP-FIX 2)" ] && [ -n "$(field_at TERMINAL 3)" ]; then
	p=$((p + 1))
	add header true "required fields occupy the first three lines exactly once"
else
	add header false "required fields must occupy the first three lines exactly once"
fi

blockers=$(field_at BLOCKERS 1)
if [[ $blockers =~ ^[1-3]$ ]]; then
	p=$((p + 1))
	add blockers true "triage retains 1-3 blocker instances from the scenario's shared root cause"
else
	add blockers false "BLOCKERS must be an integer from 1 through 3 for this scenario; got '$blockers'"
fi

KNOB='NOISE_OVERLAY_FILE|overlay 路径可配置|overlay path (is |being )?configurable'
DROP='删(掉|除)|去(掉|除)|移除|撤(掉|销|下|除)|摘(掉|除)|拿掉|砍(掉|了)|取消|不再(可配置|需要)|不可配置|改为派生|派生(出|自)|固定(死|下来)?|按约定固定|写死|收回|hardcod|derive|derived|remove|drop|eliminat|unconfigurable|non-configurable'
HARDEN='realpath|statSync|try/?catch|大小写|case-?(in)?sensitiv|case-?fold|ELOOP|EACCES|ENOENT|dev/ino|inode|basename'

top=$(field_at TOP-FIX 2)
NEGATE_DROP="(do not|don't|must not|should not|never|不要|不应|不能|勿)[^.;]{0,60}($DROP)|(keep|retain)[^.;]{0,60}(NOISE_OVERLAY_FILE|configurab)|(保留|维持)[^。；]{0,60}(NOISE_OVERLAY_FILE|可配置)"
if echo "$top" | grep -qiE "$NEGATE_DROP"; then
	add top-fix false "TOP-FIX explicitly negates deleting the unused knob. Got: '$top'"
elif echo "$top" | grep -qiE "$KNOB" && echo "$top" | grep -qiE "$DROP"; then
	p=$((p + 1))
	add top-fix true "本轮派出的修复是「删掉这个自由度」——目标类命中"
elif echo "$top" | grep -qiE "$HARDEN"; then
	add top-fix false "本轮派出的修复仍在加固守卫（第 4 次），未质疑守卫所守的自由度。得到: '$top'"
else
	add top-fix false "本轮派出的修复既非删除自由度、也未落在已知加固面。得到: '$top'"
fi

if { echo "$top" | grep -qiE "$KNOB" && echo "$top" | grep -qiE "$DROP"; } ||
	grep -iE "$KNOB" "$F" 2>/dev/null | grep -qiE "$DROP"; then
	p=$((p + 1))
	add considered true "OUTCOME 中提出过取消该自由度（即使未被选为本轮修复）"
else
	add considered false "整份 OUTCOME 从未提出过取消该自由度——没有任何 lane 问「这东西该不该存在」"
fi

terminal=$(field_at TERMINAL 3)
if [ "$terminal" = continue ]; then
	p=$((p + 1))
	add terminal true "accepted fix still requires checks and a new CR+RC round"
else
	add terminal false "TERMINAL must be continue before the root-cause approach is applied and re-reviewed; got '$terminal'"
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
