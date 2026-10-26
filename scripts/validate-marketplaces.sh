#!/usr/bin/env bash
# Fail-closed marketplace ↔ plugin consistency checks shared by release CI
# and scripts/release.sh. Exits non-zero on the first broken invariant.
#
# Does not run scripts/check-format.py — callers own the format contract.
set -euo pipefail
shopt -s nullglob

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || {
  echo "validate-marketplaces: cannot resolve repo root" >&2
  exit 1
}
cd "$root" || {
  echo "validate-marketplaces: cannot cd to repo root" >&2
  exit 1
}
die() {
  printf 'validate-marketplaces: %s\n' "$*" >&2
  exit "${2:-1}"
}

command -v jq >/dev/null 2>&1 || die "jq not found (install jq)"

# A Claude <plugin>/ dir absent from the marketplace version-bumps, passes CI,
# and ships un-installable via /plugin install.
cmf=".claude-plugin/marketplace.json"
[[ -f "$cmf" ]] || die "missing $cmf"
dirs=(*/.claude-plugin/)
# fail closed: nullglob would silently run zero checks if the layout broke
[[ ${#dirs[@]} -gt 0 ]] || die "no Claude plugin dirs matched */.claude-plugin/ — layout/glob broke"

for d in "${dirs[@]}"; do
  p="${d%/.claude-plugin/}"
  jq -e --arg s "./$p" '.plugins[] | select(.source == $s)' "$cmf" >/dev/null ||
    die "$cmf missing entry for $p"
done

# forward, Claude side: every entry must point at a real manifest whose name matches
while IFS= read -r entry; do
  cname="$(jq -r '.name // empty' <<<"$entry")"
  csrc="$(jq -r '.source // empty' <<<"$entry")"
  [[ -n "$cname" && -n "$csrc" ]] || die "$cmf has an entry without name/source"
  [[ -f "$csrc/.claude-plugin/plugin.json" ]] ||
    die "$cmf entry '$cname' points to missing manifest: $csrc/.claude-plugin/plugin.json"
  [[ "$(jq -r '.name // empty' "$csrc/.claude-plugin/plugin.json")" == "$cname" ]] ||
    die "$csrc/.claude-plugin/plugin.json name != marketplace entry '$cname'"
done < <(jq -c '.plugins[]' "$cmf")

# Every Claude plugin ships at least one skill.
for d in "${dirs[@]}"; do
  p="${d%/.claude-plugin/}"
  compgen -G "$p/skills/*/SKILL.md" >/dev/null || die "$p has no skills/*/SKILL.md — the skill itself is missing"
done

echo "validate-marketplaces: ok"
