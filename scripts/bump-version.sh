#!/usr/bin/env bash
# Sync every plugin manifest + the root marketplace manifest to one repo-wide version.
# Single source of truth for "所有版本号" — add a plugin and it's picked up automatically
# (any */.claude-plugin/plugin.json). jq is format-preserving: only the version line changes.
#
# Usage: scripts/bump-version.sh <version>     e.g. scripts/bump-version.sh 2026.6.9
#        (a leading 'v' is stripped; format must be N.N.N)
set -euo pipefail
shopt -s nullglob

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
die() { printf 'bump-version: %s\n' "$*" >&2; exit "${2:-1}"; }

ver="${1:-}"
[[ -n "$ver" ]] || die "usage: scripts/bump-version.sh <version>" 2
ver="${ver#v}"
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version '$ver' (want N.N.N, no leading v)" 2
command -v jq >/dev/null 2>&1 || die "jq not found (install jq)"

sync_json() { # <file> <jq assignment filter>
  local f="$1" filter="$2" tmp
  [[ -f "$f" ]] || return 0
  tmp="$(mktemp)"
  jq --arg v "$ver" "$filter" "$f" >"$tmp"
  if cmp -s "$f" "$tmp"; then rm -f "$tmp"; printf '  ok   %s (already %s)\n' "$f" "$ver"
  else mv "$tmp" "$f"; printf '  set  %s -> %s\n' "$f" "$ver"; fi
}

echo "bump-version: syncing all manifests -> $ver"
for f in */.claude-plugin/plugin.json; do sync_json "$f" '.version = $v'; done
sync_json ".claude-plugin/marketplace.json" '.metadata.version = $v'
