#!/usr/bin/env bash
# Cut a release locally: sync all versions -> commit -> annotated tag -> push (atomic).
# The release.yml CI then verifies the tag's manifests and opens a DRAFT GitHub release
# (you fill in the notes and Publish). The pushed tag's commit is always version-accurate.
#
# Usage: scripts/release.sh <version> [--dry-run]
#   scripts/release.sh 2026.6.9            # real release
#   scripts/release.sh 2026.6.9 --dry-run  # preview the version sync, change nothing
set -euo pipefail
shopt -s nullglob

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || { echo "release: cannot resolve repo root" >&2; exit 1; }
cd "$root" || { echo "release: cannot cd to repo root" >&2; exit 1; }
die() { printf 'release: %s\n' "$*" >&2; exit "${2:-1}"; }

ver="${1:-}"; mode="${2:-}"
[[ -n "$ver" ]] || die "usage: scripts/release.sh <version> [--dry-run]" 2
ver="${ver#v}"
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version '$ver' (want N.N.N)" 2
tag="v$ver"
files=( */.claude-plugin/plugin.json .claude-plugin/marketplace.json )

if [[ "$mode" == "--dry-run" ]]; then
  echo "release: DRY-RUN $tag — version sync preview only (no commit / tag / push):"
  # Snapshot exact current bytes (tracked OR untracked, incl. user WIP) and restore on exit,
  # so a dry-run never reverts to HEAD / never destroys uncommitted edits.
  snap="$(mktemp -d)" || die "mktemp failed"
  # shellcheck disable=SC2329  # invoked indirectly via the EXIT trap below
  _dry_restore() { local f; for f in "${files[@]}"; do [[ -e "$snap/$f" ]] && cp "$snap/$f" "$f"; done; rm -rf "$snap"; }
  trap _dry_restore EXIT
  for f in "${files[@]}"; do [[ -e "$f" ]] || continue; mkdir -p "$snap/$(dirname "$f")"; cp "$f" "$snap/$f"; done
  scripts/bump-version.sh "$ver"
  git --no-pager diff -- "${files[@]}" || true
  echo "release: (dry-run) restoring originals; a real run would commit, tag $tag, and push."
  exit 0
fi

# prechecks (fail loud, never half-release)
[[ "$(git branch --show-current)" == "main" ]] || die "not on main"
[[ -z "$(git status --porcelain)" ]] || die "working tree dirty (incl. untracked) — commit or stash first"
git fetch -q origin main || die "git fetch failed"

# recovery: a prior atomic push may have aborted, leaving the tag local-only (origin has neither
# the bump commit nor the tag). Re-push both atomically instead of dying unrecoverably.
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
  remote_tag="$(git ls-remote --tags origin "refs/tags/$tag")" || die "cannot reach origin to check tag $tag — fix connectivity and rerun"
  [[ -z "$remote_tag" ]] || die "tag $tag already released (exists on origin)"
  echo "release: tag $tag exists locally but not on origin (prior push aborted) — recovering"
  git push -q --atomic origin main "refs/tags/$tag" \
    || die "recovery push failed — if origin/main moved ahead, 'git pull --rebase origin main' then rerun; otherwise fix connectivity and rerun"
  echo "release: recovered — pushed main + $tag."
  exit 0
fi

# normal path: require main exactly in sync before mutating
[[ "$(git rev-parse HEAD)" == "$(git rev-parse FETCH_HEAD)" ]] || die "local main != origin/main — sync first"

scripts/bump-version.sh "$ver"
git add -- "${files[@]}"
git diff --cached --quiet && die "nothing to bump (already $ver everywhere)"
git commit -q -m "chore(release): 版本统一到 $ver"
git tag -a "$tag" -m "$tag"
# atomic: main + tag land together or neither — no silent half-release
git push -q --atomic origin main "refs/tags/$tag" \
  || die "push failed — local commit+tag kept; fix connectivity and rerun 'scripts/release.sh $ver' to recover"
echo "release: pushed $tag — CI is drafting the GitHub release."
echo "  edit notes & Publish: https://github.com/HerbertGao/claude-skills/releases"
