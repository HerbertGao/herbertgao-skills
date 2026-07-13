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
files=( */.claude-plugin/plugin.json codex-plugins/*/.codex-plugin/plugin.json .claude-plugin/marketplace.json )
repo_slug="${RELEASE_REPO_SLUG:-HerbertGao/herbertgao-skills}"

validate_origin_remote() {
  local remote_url
  remote_url="$(git remote get-url --push origin 2>/dev/null || git remote get-url origin 2>/dev/null)" \
    || die "cannot read origin remote"
  case "$remote_url" in
    "https://github.com/$repo_slug"|"https://github.com/$repo_slug.git"|"git@github.com:$repo_slug.git"|"ssh://git@github.com/$repo_slug.git")
      ;;
    *)
      die "origin remote '$remote_url' does not match release repo '$repo_slug'; update origin or set RELEASE_REPO_SLUG"
      ;;
  esac
}

validate_marketplaces() {
  command -v jq >/dev/null 2>&1 || die "jq not found (install jq)"
  local mf=".agents/plugins/marketplace.json"
  [[ -f "$mf" ]] || die "missing Codex marketplace: $mf"
  [[ "$(jq -r '.name // empty' "$mf")" == "herbertgao-skills-codex" ]] \
    || die "$mf name must be herbertgao-skills-codex"
  [[ "$(jq '.plugins | length' "$mf")" -gt 0 ]] || die "$mf has no plugins"

  local entry name source path manifest manifest_name
  while IFS= read -r entry; do
    name="$(jq -r '.name // empty' <<<"$entry")"
    source="$(jq -r '.source.source // empty' <<<"$entry")"
    path="$(jq -r '.source.path // empty' <<<"$entry")"
    [[ -n "$name" ]] || die "$mf has a plugin entry without name"
    [[ "$source" == "local" ]] || die "$mf entry '$name' must use local source"
    [[ -n "$path" ]] || die "$mf entry '$name' has empty source.path"
    manifest="$path/.codex-plugin/plugin.json"
    [[ -f "$manifest" ]] || die "$mf entry '$name' points to missing manifest: $manifest"
    manifest_name="$(jq -r '.name // empty' "$manifest")"
    [[ "$manifest_name" == "$name" ]] || die "$manifest name '$manifest_name' != marketplace entry '$name'"
  done < <(jq -c '.plugins[]' "$mf")

  # reverse: every codex-plugins/<dir> must be registered, or it silently ships uninstallable
  local d
  for d in codex-plugins/*/; do
    jq -e --arg p "./${d%/}" '.plugins[] | select(.source.path == $p)' "$mf" >/dev/null \
      || die "$mf missing entry for $d"
  done

  # same asymmetry on the Claude side: a <plugin>/ dir absent from the Claude marketplace
  # version-bumps, passes CI, and ships un-installable via /plugin install.
  local cmf=".claude-plugin/marketplace.json" p dirs=( */.claude-plugin/ )
  # fail closed: nullglob would silently run zero checks if the layout broke
  [[ ${#dirs[@]} -gt 0 ]] || die "no Claude plugin dirs matched */.claude-plugin/ — layout/glob broke"
  for d in "${dirs[@]}"; do
    p="${d%/.claude-plugin/}"
    jq -e --arg s "./$p" '.plugins[] | select(.source == $s)' "$cmf" >/dev/null \
      || die "$cmf missing entry for $p"
  done

  # forward, Claude side: every entry must point at a real manifest whose name matches
  local csrc cname
  while IFS= read -r entry; do
    cname="$(jq -r '.name // empty' <<<"$entry")"
    csrc="$(jq -r '.source // empty' <<<"$entry")"
    [[ -n "$cname" && -n "$csrc" ]] || die "$cmf has an entry without name/source"
    [[ -f "$csrc/.claude-plugin/plugin.json" ]] \
      || die "$cmf entry '$cname' points to missing manifest: $csrc/.claude-plugin/plugin.json"
    [[ "$(jq -r '.name // empty' "$csrc/.claude-plugin/plugin.json")" == "$cname" ]] \
      || die "$csrc/.claude-plugin/plugin.json name != marketplace entry '$cname'"
  done < <(jq -c '.plugins[]' "$cmf")

  # README declares per-skill pairing: every universal skill ships a byte-identical Codex copy,
  # and every Codex skill dir is a COMPLETE pair (SKILL.md + agents/openai.yaml) backed by a
  # universal source. Every glob fails closed — a paired deletion (source + copy together) must
  # die too, not slip through zero loop iterations.
  local srcs=( skills/*/SKILL.md ) s t twins p
  [[ ${#srcs[@]} -gt 0 ]] || die "no universal skills matched skills/*/SKILL.md — layout/glob broke"
  for s in "${srcs[@]}"; do
    twins=( codex-plugins/*/"$s" )
    [[ ${#twins[@]} -gt 0 ]] || die "no Codex twin found for $s — every skills/*/SKILL.md needs one"
    for t in "${twins[@]}"; do
      cmp -s "$s" "$t" || die "twin drift: $t is not a byte-copy of $s — re-sync before releasing"
    done
  done
  # every Codex skill dir: complete pair, backed by a universal source
  for t in codex-plugins/*/skills/*/; do
    [[ -f "${t}SKILL.md" ]] || die "Codex skill missing its SKILL.md: $t"
    [[ -f "${t}agents/openai.yaml" ]] || die "Codex skill missing its agents/openai.yaml: $t"
    s="skills/$(basename "$t")/SKILL.md"
    [[ -f "$s" ]] || die "orphan Codex skill: $t has no $s to copy from"
  done
  # every Codex plugin ships at least one skill; every Claude plugin ships its skill
  for d in codex-plugins/*/; do
    compgen -G "${d}skills/*/SKILL.md" >/dev/null || die "$d ships no skill (no skills/*/SKILL.md)"
  done
  for d in "${dirs[@]}"; do
    p="${d%/.claude-plugin/}"
    compgen -G "$p/skills/*/SKILL.md" >/dev/null || die "$p has no skills/*/SKILL.md — the skill itself is missing"
  done
}

if [[ "$mode" == "--dry-run" ]]; then
  echo "release: DRY-RUN $tag — version sync preview only (no commit / tag / push):"
  # Snapshot exact current bytes (tracked OR untracked, incl. user WIP) and restore on exit,
  # so a dry-run never reverts to HEAD / never destroys uncommitted edits.
  snap="$(mktemp -d)" || die "mktemp failed"
  # shellcheck disable=SC2329  # invoked indirectly via the EXIT trap below
  _dry_restore() { local f; for f in "${files[@]}"; do [[ -e "$snap/$f" ]] && cp "$snap/$f" "$f"; done; rm -rf "$snap"; }
  trap _dry_restore EXIT
  for f in "${files[@]}"; do [[ -e "$f" ]] || continue; mkdir -p "$snap/$(dirname "$f")"; cp "$f" "$snap/$f"; done
  validate_marketplaces
  scripts/bump-version.sh "$ver"
  git --no-pager diff -- "${files[@]}" || true
  echo "release: (dry-run) restoring originals; a real run would commit, tag $tag, and push."
  exit 0
fi

# prechecks (fail loud, never half-release)
[[ "$(git branch --show-current)" == "main" ]] || die "not on main"
[[ -z "$(git status --porcelain)" ]] || die "working tree dirty (incl. untracked) — commit or stash first"
validate_origin_remote
validate_marketplaces
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
echo "  edit notes & Publish: https://github.com/$repo_slug/releases"
