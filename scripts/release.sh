#!/usr/bin/env bash
# Cut a release locally: sync all versions -> commit -> annotated tag -> push.
# The release.yml CI then verifies the tag's manifests and opens a DRAFT GitHub release
# (you fill in the notes and Publish). The pushed tag's commit is always version-accurate.
#
# Usage: scripts/release.sh <version> [--dry-run]
#   scripts/release.sh 2026.6.9            # real release
#   scripts/release.sh 2026.6.9 --dry-run  # preview the version sync, change nothing
set -euo pipefail
shopt -s nullglob

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
die() { printf 'release: %s\n' "$*" >&2; exit "${2:-1}"; }

ver="${1:-}"; mode="${2:-}"
[[ -n "$ver" ]] || die "usage: scripts/release.sh <version> [--dry-run]" 2
ver="${ver#v}"
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version '$ver' (want N.N.N)" 2
tag="v$ver"
files=( */.claude-plugin/plugin.json .claude-plugin/marketplace.json )

if [[ "$mode" == "--dry-run" ]]; then
  echo "release: DRY-RUN $tag — version sync preview only (no commit / tag / push):"
  scripts/bump-version.sh "$ver"
  git --no-pager diff -- "${files[@]}" || true
  git checkout -- "${files[@]}" 2>/dev/null || true
  echo "release: (dry-run) reverted; a real run would commit, tag $tag, and push."
  exit 0
fi

# prechecks (fail loud, never half-release)
[[ "$(git branch --show-current)" == "main" ]] || die "not on main"
git diff --quiet && git diff --cached --quiet || die "working tree dirty — commit or stash first"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1 && die "tag $tag already exists"
git fetch -q origin main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse FETCH_HEAD)" ]] || die "local main != origin/main — sync first"

scripts/bump-version.sh "$ver"
git add -- "${files[@]}"
git diff --cached --quiet && die "nothing to bump (already $ver everywhere)"
git commit -q -m "chore(release): 版本统一到 $ver"
git tag -a "$tag" -m "$tag"
git push -q origin main
git push -q origin "$tag"
echo "release: pushed $tag — CI is drafting the GitHub release."
echo "  edit notes & Publish: https://github.com/HerbertGao/claude-skills/releases"
