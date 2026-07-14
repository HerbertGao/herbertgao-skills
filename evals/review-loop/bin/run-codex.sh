#!/usr/bin/env bash
# HOME isolation runner: the skill resolves ~/.agency-agents against an empty fake HOME,
# while codex keeps its real (file-based) auth via CODEX_HOME. No API key needed.
set -euo pipefail
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
export HOME="$PWD/.fakehome"
mkdir -p "$HOME"
exec codex exec --skip-git-repo-check --sandbox workspace-write -
