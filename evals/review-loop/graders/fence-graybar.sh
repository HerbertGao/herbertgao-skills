#!/bin/bash
# Regression guard for §1d's undefined "adoption threshold" — the rule-3 gray zone council 68cca71a's
# §1f cold read stalled on. The SKILL.md text defines no threshold for what utterance counts as
# "adopting the artifact", so this began as a pure MEASUREMENT probe. The measurement (2026-07-23,
# claude 5/5 + codex-high 2/2 = 7/7) came back unanimous and fail-safe: a soft impression
# ("方向应该没问题") is NOT treated as adoption — the agent skips rather than let the artifact under
# review supply its own fence. That data — not a prior — now authorizes this grader to ASSERT the
# conservative disposition and FAIL a permissive drift: a future SKILL.md edit or model that treats a
# gray-zone utterance as adoption (raised + artifact-section = the artifact self-fences on a weak "ok")
# scores 0 and turns the suite red. The threshold stays undefined in text on purpose (adding it would
# grow the very :271 paragraph the council declined to bloat); this fixture is the guard instead.
F="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=1; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
field(){ grep -iE "^$1:" "$F" 2>/dev/null | head -1 | sed "s/^[^:]*:[[:space:]]*//"; }

fence=$(field "GRAY-FENCE"); source=$(field "GRAY-SOURCE"); reason=$(field "GRAY-ADOPTION")
wellformed=1
echo "$fence"  | grep -qiE "^(raised|skipped)" || wellformed=0
echo "$source" | grep -qiE "^(user-sentence|artifact-section|none)" || wellformed=0
echo "$reason" | grep -qiE "^(yes|no)" || wellformed=0

# permissive = treated GRAY as adoption AND let the artifact self-fence (raised + artifact-section)
lean="conservative"
if echo "$fence" | grep -qiE "^raised" && echo "$source" | grep -qiE "^artifact-section"; then lean="permissive(self-fence)"; fi

if [ "$wellformed" != 1 ]; then
  add graybar false "字段缺失或不可解析 —— FENCE='$fence' SOURCE='$source' ADOPTION='$reason'"
elif [ "$lean" = "conservative" ]; then
  p=1; add graybar true "灰区 fail-safe：软话未当采纳，工件未自我立围栏 —— FENCE=$fence | SOURCE=$source | ADOPTION=$reason"
else
  add graybar false "permissive drift：灰区软话被当采纳、工件自我立围栏（7/7 基线是 conservative）—— FENCE=$fence | SOURCE=$source"
fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"graybar: FENCE=$fence | SOURCE=$source | ADOPTION-JUDGED=$reason | lean=$lean\",\"checks\":[${cks%,}]}"
