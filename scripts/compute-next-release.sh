#!/usr/bin/env bash
# Decide the next release version for auto prepare-release (push to main).
# CalVer YEAR.MONTH.SEQ in Asia/Shanghai (month unpadded, matching repo tags);
# writes GITHUB_OUTPUT: skip, version, branch, tag, reason.
set -euo pipefail

out="${GITHUB_OUTPUT:?GITHUB_OUTPUT must be set}"

write_out() {
  printf '%s\n' "$@" >>"$out"
}

calver_year() {
  TZ=Asia/Shanghai date +%Y
}

# Unpadded month (GNU date on ubuntu-latest): 2026.8.9 not 2026.08.9
calver_month() {
  TZ=Asia/Shanghai date +%-m
}

calver_now() {
  printf '%s.%s\n' "$(calver_year)" "$(calver_month)"
}

version_in_current_calver_month() {
  local ver="$1" vy vm _vs
  IFS='.' read -r vy vm _vs <<<"$ver"
  [[ -n "$vy" && -n "$vm" ]] || return 1
  vm=$((10#$vm))
  [[ "$vy" == "$(calver_year)" && "$vm" -eq $((10#$(calver_month))) ]]
}

# Next SEQ from a base version (latest tag or in-month manifest).
compute_next_from_base() {
  local base_ver="${1:-}"
  local cy cm_out
  cy="$(calver_year)"
  cm_out="$(calver_month)"

  if [[ -z "$base_ver" ]]; then
    printf '%s.%s.0\n' "$cy" "$cm_out"
    return 0
  fi

  local by bm bs
  IFS='.' read -r by bm bs <<<"$base_ver"
  [[ -n "$by" && -n "$bm" && -n "$bs" ]] || return 1
  bm=$((10#$bm))
  local cm_num=$((10#$(calver_month)))

  if [[ "$by" == "$cy" && "$bm" -eq "$cm_num" ]]; then
    printf '%s.%s.%s\n' "$cy" "$cm_out" "$((bs + 1))"
  else
    printf '%s.%s.0\n' "$cy" "$cm_out"
  fi
}

tag_exists_remote_or_local() {
  local tag="$1"
  git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1 ||
    git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1
}

latest_tag="$(
  git tag -l 'v[0-9]*' --sort=-version:refname 2>/dev/null | head -1 || true
)"

if [[ -n "$latest_tag" ]]; then
  range="${latest_tag}..HEAD"
  base_ver="${latest_tag#v}"
else
  range="HEAD"
  manifest_ver="$(jq -r '.metadata.version // empty' .claude-plugin/marketplace.json 2>/dev/null || true)"
  if version_in_current_calver_month "$manifest_ver"; then
    base_ver="$manifest_ver"
  else
    base_ver=""
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

expected_ver="$(compute_next_from_base "$base_ver")" || {
  write_out "skip=true"
  write_out "reason=cannot compute CalVer from base '${base_ver:-empty}'"
  exit 0
}

ver="$expected_ver"
reason="CalVer $(calver_now).SEQ from ${latest_tag:-${base_ver:-month start}} -> $ver (Asia/Shanghai, unpadded month)"

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
  open_ver="${open_branch#release/v}"
  if [[ "$open_ver" == "$expected_ver" ]] && ! tag_exists_remote_or_local "v$open_ver"; then
    ver="$open_ver"
    reason="reuse open release PR $open_branch (matches CalVer next $expected_ver)"
  fi
fi

if [[ ! "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  write_out "skip=true"
  write_out "reason=invalid computed version '$ver'"
  exit 0
fi

if tag_exists_remote_or_local "v$ver"; then
  write_out "skip=true"
  write_out "reason=tag v$ver already exists"
  exit 0
fi

write_out "skip=false"
write_out "version=$ver"
write_out "branch=release/v$ver"
write_out "tag=v$ver"
write_out "reason=$reason"