#!/bin/bash
# Grades OUTCOME.md for §1f authority-aware / read-set classification (#13 / #15).
# A cold read of a 2-file bundle that references two OpenAPI contracts pinned by
# path+version+sha256 (external, not in the read-set) plus genuine local gaps.
#   1. the pinned OpenAPI refs must NOT count toward the blocking unfollowable-local total
#      (external-reference-required) — the #13 false positive killed;
#   2. the genuine local gaps must still count as unfollowable-local — real problems still block;
#   3. project coinage (WorkRecord) counts as undefined; standard nouns (ASGI/canary/principal) do not.
p=0; t=3; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

if grep -qiE "^PINNED-OPENAPI-COUNTS-TOWARD-GATE:[[:space:]]*no" OUTCOME.md 2>/dev/null; then
  p=$((p+1)); add extref true "钉死 OpenAPI 判 external-reference-required，不计门（#13 假阳性已死）"
else add extref false "钉死 OpenAPI 仍被计入 unfollowable-local（#13 假阳性未消）"; fi

n=$(grep -iE "^UNFOLLOWABLE-LOCAL-COUNT:" OUTCOME.md 2>/dev/null | grep -oE "[0-9]+" | head -1)
n=${n:-0}
if [ "$n" -ge 1 ]; then p=$((p+1)); add localgap true "真实本地缺口仍判 unfollowable-local（阻断保留）"
else add localgap false "本地缺口未被判 unfollowable-local——门被架空"; fi

if grep -qiE "^UNDEFINED-TERMS:.*WorkRecord" OUTCOME.md 2>/dev/null && ! grep -qiE "^UNDEFINED-TERMS:.*(ASGI|canary|principal)" OUTCOME.md 2>/dev/null; then
  p=$((p+1)); add undef true "只数自造词 WorkRecord；标准名词 ASGI/canary/principal 不计"
else add undef false "undefined 计数错误（漏 WorkRecord 或把标准名词计入）"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
