#!/usr/bin/env bash
# Deterministic grader for the portable review-loop protocol probes.
set -euo pipefail
mode=${1:?usage: protocol.sh <routing|experts|root-cause|output-retention>}
outcome=${OUTCOME_FILE:-OUTCOME.md}
checks=$(mktemp "${TMPDIR:-/tmp}/review-protocol.XXXXXX")
trap 'rm -f "$checks"' EXIT
p=0
t=0
add() {
	local name=$1 passed=$2
	t=$((t + 1))
	[ "$passed" = true ] && p=$((p + 1))
	printf '%s\t%s\n' "$name" "$passed" >>"$checks"
}
exact_prefix() {
	local expected=$1 n=0 want got label matches total
	while IFS= read -r want; do
		n=$((n + 1))
		got=$(sed -n "${n}p" "$outcome" 2>/dev/null || true)
		if [ "$got" = "$want" ]; then add "line-$n" true; else add "line-$n" false; fi
		label=${want%%:*}
		matches=$(grep -cE "^[[:space:]]*${label}:" "$outcome" 2>/dev/null || true)
		if [ "$matches" = 1 ]; then add "unique-$label" true; else add "unique-$label" false; fi
	done <<EOF
$expected
EOF
	total=$(grep -cve '^[[:space:]]*$' "$outcome" 2>/dev/null || true)
	total=${total:-0}
	if [ "$total" = "$n" ]; then add exact-lines true; else add exact-lines false; fi
}
exact_fields() {
	local expected=$1 label matches got
	while IFS= read -r want; do
		label=${want%%:*}
		matches=$(grep -E "^[[:space:]]*${label}:[[:space:]]*" "$outcome" 2>/dev/null || true)
		got=$(printf '%s\n' "$matches" | sed -E 's/^[[:space:]]*//; s/[[:space:]]+$//')
		if [ "$(printf '%s\n' "$matches" | grep -c . || true)" = 1 ] && [ "$got" = "$want" ]; then
			add "field-$label" true
		else
			add "field-$label" false
		fi
	done <<EOF
$expected
EOF
}
case "$mode" in
routing)
	exact_prefix "$(
		cat <<'EOF'
CASE-A: blocked=no, route-recorded=no, return=full
CASE-B: blocked=no, route-recorded=no, return=summary-ok
CASE-C: blocked=no, route-recorded=no, catalog=continue
CASE-D: blocked=no, route-recorded=no, passes=sequential-withheld
CASE-E: blocked=no, worktree=not-requested, access=absolute-path
CATALOG-MISSING: continue
SANDBOX-MISSING: continue
EOF
	)"
	;;
experts)
	eligible=$(sed -n '1p' "$outcome" 2>/dev/null || true)
	ineligible=$(sed -n '2p' "$outcome" 2>/dev/null || true)
	selections=$(sed -n '3p' "$outcome" 2>/dev/null | sed -E 's/[[:space:]]*\+[[:space:]]*/ + /g' || true)
	cap=$(sed -n '4p' "$outcome" 2>/dev/null || true)
	missing=$(sed -n '5p' "$outcome" 2>/dev/null || true)
	authority=$(sed -n '6p' "$outcome" 2>/dev/null || true)
	if [ "$eligible" = 'ELIGIBLE: WeChat Mini Program Developer, Accessibility Auditor' ]; then add eligible true; else add eligible false; fi
	if [ "$ineligible" = 'INELIGIBLE: Frontend Developer, Software Architect, WeChat Official Account Specialist' ]; then add ineligible true; else add ineligible false; fi
	if [ "$selections" = 'VALID-SELECTIONS: none | WeChat Mini Program Developer | Accessibility Auditor | WeChat Mini Program Developer + Accessibility Auditor' ]; then add selections true; else add selections false; fi
	if [ "$cap" = 'EXPERT-SEAT-CAP: none' ]; then add cap true; else add cap false; fi
	if [ "$missing" = 'CATALOG-MISSING: continue-cr-rc-without-experts' ]; then add catalog-missing true; else add catalog-missing false; fi
	if [ "$authority" = 'EXPERT-AUTHORITY: findings-only' ]; then add authority true; else add authority false; fi
	unique=true
	for label in ELIGIBLE INELIGIBLE VALID-SELECTIONS EXPERT-SEAT-CAP CATALOG-MISSING EXPERT-AUTHORITY; do
		[ "$(grep -cE "^[[:space:]]*${label}:" "$outcome" 2>/dev/null || true)" = 1 ] || unique=false
	done
	add unique-fields "$unique"
	;;
root-cause)
	exact_prefix "$(
		cat <<'EOF'
CASE-A-ACTION: one-fresh-person
CASE-A-TERMINAL: continue
CASE-B-TERMINAL: NOT-CONVERGED
CASE-C-ACTION: no-escalation
CASE-D-TERMINAL: NOT-CONVERGED
CASE-E-TERMINAL: OUT-OF-SCOPE-PENDING
GLOBAL-BUDGET: none
EOF
	)"
	;;
output-retention)
	exact_fields "$(
		cat <<'EOF'
A: forward
B: normalize
C: stop
D: stop
R4: waive
SOFT-CHAIN: not-merged
SOFT-ACTION: no-escalation
HARD-GUARD: keep
PATCH: simplify
EOF
	)"
	;;
*)
	echo "unknown mode: $mode" >&2
	exit 2
	;;
esac
P=$p T=$t CHECKS=$checks python3 - <<'PY'
import json, os
rows = []
with open(os.environ["CHECKS"], encoding="utf-8") as f:
    for row in f:
        name, passed = row.rstrip("\n").split("\t")
        rows.append({"name": name, "passed": passed == "true", "message": "protocol classification"})
p, t = int(os.environ["P"]), int(os.environ["T"])
score = 1.0 if p == t else 0.0
print(json.dumps({"score": score, "details": f"{p}/{t} checks", "checks": rows}, separators=(",", ":")))
PY
