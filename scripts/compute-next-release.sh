#!/usr/bin/env bash
# Decide the next release version for auto prepare-release (push to main).
# Writes GITHUB_OUTPUT: skip, version, branch, tag, reason.
# Patch bump from the latest vN.N.N tag unless an open release/v* PR already
# pins the in-flight version (one release PR at a time; refresh that branch).
set -euo pipefail

out="${GITHUB_OUTPUT:?GITHUB_OUTPUT must be set}"

write_out() {
  printf '%s\n' "$@" >>"$out"
}

bump_patch() {
  local ver="$1" a b c
  IFS='.' read -r a b c <<<"$ver"
  [[ -n "$a" && -n "$b" && -n "$c" ]] || return 1
  printf '%s.%s.%s\n' "$a" "$b" "$((c + 1))"
}

latest_tag="$(
  git tag -l 'v[0-9]*' --sort=-version:refname 2>/dev/null | head -1 || true
)"

if [[ -n "$latest_tag" ]]; then
  range="${latest_tag}..HEAD"
  base_ver="${latest_tag#v}"
else
  range="HEAD"
  base_ver="$(jq -r '.metadata.version // empty' .claude-plugin/marketplace.json 2>/dev/null || true)"
  if [[ -z "$base_ver" ]]; then
    write_out "skip=true"
    write_out "reason=no tags and no marketplace metadata.version"
    exit 0
  fi
fi

releasable="$(
  git log "$range" --pretty=%s 2>/dev/null |
    grep -Ev '^chore\(release\):' |
    grep -E '^(feat|fix|refactor|perf|docs|chore|ci|build|style|test)(\(|:)' ||
    true
)"

if [[ -z "$releasable" ]]; then
  write_out "skip=true"
  write_out "reason=no releasable commits since ${latest_tag:-repo start}"
  exit 0
fi

open_branch=""
if command -v gh >/dev/null 2>&1 && [[ -n "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then
  open_branch="$(
    gh pr list --base main --state open --json headRefName \
      -q '.[].headRefName' 2>/dev/null |
      grep -E '^release/v[0-9]+\.[0-9]+\.[0-9]+$' |
      head -1 || true
  )"
fi

if [[ -n "$open_branch" ]]; then
  ver="${open_branch#release/v}"
  reason="reuse open release PR branch $open_branch"
else
  ver="$(bump_patch "$base_ver")" || {
    write_out "skip=true"
    write_out "reason=cannot patch-bump base version '$base_ver'"
    exit 0
  }
  reason="patch bump from ${latest_tag:-manifest $base_ver}"
fi

if [[ ! "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  write_out "skip=true"
  write_out "reason=invalid computed version '$ver'"
  exit 0
fi

if git rev-parse -q --verify "refs/tags/v$ver" >/dev/null 2>&1 ||
  git ls-remote --exit-code --tags origin "refs/tags/v$ver" >/dev/null 2>&1; then
  write_out "skip=true"
  write_out "reason=tag v$ver already exists"
  exit 0
fi

write_out "skip=false"
write_out "version=$ver"
write_out "branch=release/v$ver"
write_out "tag=v$ver"
write_out "reason=$reason"