#!/usr/bin/env bash
# Sync every plugin manifest + the root marketplace manifest to one repo-wide version.
# Single source of truth for "所有版本号" — add a plugin and it's picked up automatically
# (any */.claude-plugin/plugin.json). jq is format-preserving: only the version line changes.
#
# Two-phase / atomic: render every manifest into a temp dir first; only if ALL jq succeed
# are originals overwritten — a mid-list jq failure changes nothing (no half-synced tree).
#
# Usage: scripts/bump-version.sh <version>     e.g. scripts/bump-version.sh 2026.6.9
#        (a leading 'v' is stripped; format must be N.N.N)
set -euo pipefail
shopt -s nullglob

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || { echo "bump-version: cannot resolve repo root" >&2; exit 1; }
cd "$root" || { echo "bump-version: cannot cd to repo root" >&2; exit 1; }
die() { printf 'bump-version: %s\n' "$*" >&2; exit "${2:-1}"; }

ver="${1:-}"
[[ -n "$ver" ]] || die "usage: scripts/bump-version.sh <version>" 2
ver="${ver#v}"
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version '$ver' (want N.N.N, no leading v)" 2
command -v jq >/dev/null 2>&1 || die "jq not found (install jq)"

# targets: "<file>\t<jq filter>"  — every plugin .version + root marketplace .metadata.version
targets=()
for f in */.claude-plugin/plugin.json; do targets+=("$f"$'\t'".version = \$v"); done
[[ -f .claude-plugin/marketplace.json ]] && targets+=(".claude-plugin/marketplace.json"$'\t'".metadata.version = \$v")
[[ ${#targets[@]} -gt 0 ]] || die "no manifests found (*/.claude-plugin/plugin.json) — wrong layout?"

work="$(mktemp -d)" || die "mktemp failed"
trap 'rm -rf "$work"' EXIT

# phase 1 — render all into $work; any jq failure dies here, before touching originals
planned=()
for t in "${targets[@]}"; do
  f="${t%%$'\t'*}"; filter="${t#*$'\t'}"
  mkdir -p "$work/$(dirname "$f")"
  # shellcheck disable=SC2016  # $v is a jq --arg variable; must stay literal (not shell-expanded)
  jq --arg v "$ver" "$filter" "$f" >"$work/$f" || die "jq failed on $f — nothing changed"
  planned+=("$f")
done

# phase 2 — overwrite only files whose content actually changed
echo "bump-version: syncing all manifests -> $ver"
for f in "${planned[@]}"; do
  if cmp -s "$f" "$work/$f"; then printf '  ok   %s (already %s)\n' "$f" "$ver"
  else cp "$work/$f" "$f"; printf '  set  %s -> %s\n' "$f" "$ver"; fi
done
