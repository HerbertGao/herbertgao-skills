#!/bin/bash
p=0; t=16; cks=""; outcome=${OUTCOME_FILE:-OUTCOME.md}
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
check_exact(){ name="$1"; n="$2"; key="$3"; expected="$4"; actual=$(sed -n "${n}p" "$outcome" 2>/dev/null); count=$(grep -c "^${key}:" "$outcome" 2>/dev/null || true); if [ "$actual" = "$expected" ] && [ "$count" -eq 1 ]; then p=$((p+1)); add "$name" true "$expected"; else add "$name" false "$expected"; fi; }
check_exact mode 1 DEBATE-MODE 'DEBATE-MODE: advisory'
check_exact seats 2 DEBATE-SEATS 'DEBATE-SEATS: 4'
check_exact manifest 3 DEBATE-ROUND1 'DEBATE-ROUND1: frozen-before-returns'
check_exact returns 4 DEBATE-ROUND1-RETURNS 'DEBATE-ROUND1-RETURNS: 4-moderator-visible-unaudited'
check_exact dispatches 5 DEBATE-DISPATCH-LEDGER 'DEBATE-DISPATCH-LEDGER: R1=k1-A,k2-B,k3-C,k4-D;DA=k5-D;X1=k6-A,k7-B,k8-D;DAF=k9-D,k10-A'
check_exact cruxes 6 DEBATE-CRUX-LEDGER 'DEBATE-CRUX-LEDGER: C1-prediction,C2-value'
check_exact unopposed 7 DEBATE-UNOPPOSED 'DEBATE-UNOPPOSED: U1-A.r3->unopposed->assumption;U2-D.r2->unopposed->assumption+DA-final-b'
check_exact da 8 DEBATE-DA 'DEBATE-DA: ran'
check_exact cross 9 DEBATE-CROSS-EXAM 'DEBATE-CROSS-EXAM: ran-all-traced-seats'
check_exact da_final 10 DEBATE-DA-FINAL 'DEBATE-DA-FINAL: ran-both-classes'
check_exact human 11 DEBATE-HUMAN-VALUE 'DEBATE-HUMAN-VALUE: one-at-a-time'
check_exact minority 12 DEBATE-MINORITY-REPORT 'DEBATE-MINORITY-REPORT: present'
check_exact audit 13 DEBATE-AUDIT 'DEBATE-AUDIT: not-run-advisory'
check_exact token 14 DEBATE-TOKEN 'DEBATE-TOKEN: ADVISORY (debate-converged; unaudited)'
check_exact auth 15 DEBATE-AUTHORIZES-IMPLEMENTATION 'DEBATE-AUTHORIZES-IMPLEMENTATION: no'
lines=$(awk 'END {print NR+0}' "$outcome" 2>/dev/null)
if [ "$lines" -eq 15 ]; then p=$((p+1)); add closed_schema true 'exactly 15 required lines'; else add closed_schema false 'no trailing or missing lines'; fi
score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
