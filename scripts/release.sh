#!/usr/bin/env bash
# Cut a release via GitHub Actions (pi-extensions-style), not local tag+push.
#
# Dispatches .github/workflows/release.yml with the given version. CI opens or
# updates a release PR that bumps manifests via bump-version.sh. Merging that
# PR to main creates annotated tag vN.N.N and publishes a GitHub Release.
#
# Usage: scripts/release.sh <version> [--dry-run]
#   scripts/release.sh 2026.10.2            # dispatch prepare-release workflow
#   scripts/release.sh 2026.10.2 --dry-run  # preview the version sync locally
set -euo pipefail
shopt -s nullglob

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || {
  echo "release: cannot resolve repo root" >&2
  exit 1
}
cd "$root" || {
  echo "release: cannot cd to repo root" >&2
  exit 1
}
die() {
  printf 'release: %s\n' "$*" >&2
  exit "${2:-1}"
}

ver="${1:-}"
mode="${2:-}"
[[ -n "$ver" ]] || die "usage: scripts/release.sh <version> [--dry-run]" 2
ver="${ver#v}"
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version '$ver' (want N.N.N)" 2
tag="v$ver"
files=(*/.claude-plugin/plugin.json .claude-plugin/marketplace.json)
repo_slug="${RELEASE_REPO_SLUG:-HerbertGao/herbertgao-skills}"

validate_origin_remote() {
  local remote_url
  remote_url="$(git remote get-url --push origin 2>/dev/null || git remote get-url origin 2>/dev/null)" ||
    die "cannot read origin remote"
  case "$remote_url" in
  "https://github.com/$repo_slug" | "https://github.com/$repo_slug.git" | "git@github.com:$repo_slug.git" | "ssh://git@github.com/$repo_slug.git")
    ;;
  *)
    die "origin remote '$remote_url' does not match release repo '$repo_slug'; update origin or set RELEASE_REPO_SLUG"
    ;;
  esac
}

if [[ "$mode" == "--dry-run" ]]; then
  echo "release: DRY-RUN $tag — version sync preview only (no PR / tag / push):"
  # Snapshot exact current bytes (tracked OR untracked, incl. user WIP) and restore on exit,
  # so a dry-run never reverts to HEAD / never destroys uncommitted edits.
  snap="$(mktemp -d)" || die "mktemp failed"
  # shellcheck disable=SC2329  # invoked indirectly via the EXIT trap below
  _dry_restore() {
    local f
    for f in "${files[@]}"; do [[ -e "$snap/$f" ]] && cp "$snap/$f" "$f"; done
    rm -rf "$snap"
  }
  trap _dry_restore EXIT
  for f in "${files[@]}"; do
    [[ -e "$f" ]] || continue
    mkdir -p "$snap/$(dirname "$f")"
    cp "$f" "$snap/$f"
  done
  bash scripts/validate-marketplaces.sh
  # Prefer a real catalog when present; otherwise waive like CI contract job.
  if [[ -d "${HOME}/.agency-agents" ]]; then
    env -u SKIP_CATALOG_CHECK -u AGENCY_AGENTS scripts/check-format.py ||
      die "format contract violated (contracts/format.json)"
  else
    SKIP_CATALOG_CHECK=1 scripts/check-format.py ||
      die "format contract violated (contracts/format.json)"
  fi
  scripts/bump-version.sh "$ver"
  for f in "${files[@]}"; do
    if [[ "$f" == ".claude-plugin/marketplace.json" ]]; then
      got="$(jq -r '.metadata.version // empty' "$f")"
    else
      got="$(jq -r '.version // empty' "$f")"
    fi
    [[ "$got" == "$ver" ]] || die "$f version '$got' != requested '$ver'"
  done
  git --no-pager diff -- "${files[@]}" || true
  echo "release: (dry-run) restoring originals; a real run would dispatch the release workflow."
  exit 0
fi

[[ -z "$mode" ]] || die "unknown option '$mode' (only --dry-run is supported)" 2
command -v gh >/dev/null 2>&1 || die "gh not found — install GitHub CLI, or run: gh workflow run release.yml -f version=$ver"
validate_origin_remote

# Local preflight so an obviously broken tree fails before CI spins up.
bash scripts/validate-marketplaces.sh
if [[ -d "${HOME}/.agency-agents" ]]; then
  env -u SKIP_CATALOG_CHECK -u AGENCY_AGENTS scripts/check-format.py ||
    die "format contract violated (contracts/format.json) — fix before releasing"
else
  SKIP_CATALOG_CHECK=1 scripts/check-format.py ||
    die "format contract violated (contracts/format.json) — fix before releasing"
fi

echo "release: dispatching prepare-release for $tag on $repo_slug"
gh workflow run release.yml --repo "$repo_slug" -f "version=$ver"

echo "release: workflow dispatched."
echo "  watch:  gh run list --repo $repo_slug --workflow=release.yml --limit 3"
echo "  merge the release PR when green; merging publishes $tag (not a draft)."
echo "  releases: https://github.com/$repo_slug/releases"
