#!/usr/bin/env bash
# =============================================================================
# Claude Code kit installer — macOS / Linux  (HYBRID install)
# =============================================================================
# Idempotent. Safe to run by a human OR an AI agent. Never deletes; never
# clobbers existing config (merges with jq).
#
# Layout (hybrid):
#   • Statusline       → USER level  (~/.claude)            — same in every project
#   • Commands/agents/
#     skills/hook/etc. → PROJECT level (<repo>/.claude)     — local to the repo
#   • <repo>/.claude   → added to <repo>/.gitignore         — tooling, not committed
#   • Durable docs (PRDs, plans, changelog) live OUTSIDE .claude, at the repo
#     root under docs/ (created by the pipeline / `/documentation`).
#
# Usage:
#   ./install.sh                 # hybrid install into the current repo
#   ./install.sh /path/to/repo   # hybrid install into another repo
#   ./install.sh ~/              # "global": everything into ~/.claude (no split)
#
# Env:
#   CLAUDE_CONFIG_DIR=<dir>   user config dir (default ~/.claude)
#   FORCE_STATUSLINE=1        replace an existing statusLine without asking
# =============================================================================
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_VERSION="$(cat "$KIT_DIR/VERSION" 2>/dev/null || echo unknown)"
if git -C "$KIT_DIR" rev-parse --short HEAD >/dev/null 2>&1; then
  KIT_VERSION="$KIT_VERSION+$(git -C "$KIT_DIR" rev-parse --short HEAD)"
fi

# --- Resolve targets -------------------------------------------------------
if [[ $# -ge 1 ]]; then
  PROJECT="$(cd "$1" 2>/dev/null && pwd || true)"
  [[ -z "$PROJECT" ]] && { echo "✗ Target dir not found: $1" >&2; exit 1; }
else
  PROJECT="$PWD"
fi
USER_DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PROJ_DEST="$PROJECT/.claude"

# "Global" mode: project's .claude IS the user dir → no split.
HYBRID=true
[[ "$PROJ_DEST" == "$USER_DEST" ]] && HYBRID=false

log() { printf '  %s\n' "$*"; }
echo "▶ Installing Claude Code kit $KIT_VERSION ($([[ "$HYBRID" == true ]] && echo hybrid || echo global))"
log "kit:     $KIT_DIR"
log "user:    $USER_DEST"
[[ "$HYBRID" == true ]] && log "project: $PROJ_DEST"

# --- Dependency check ------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }
have jq || { echo "✗ 'jq' is required to merge settings.json. Install it and re-run." >&2; exit 1; }
for dep in git bc; do have "$dep" || log "⚠ optional dependency missing: $dep (statusline needs it)"; done

# --- OS detection → statusline script --------------------------------------
SL_CMD=""
case "$(uname -s)" in
  Darwin) SL_CMD="bash \"$USER_DEST/statusline/statusline-command-macos.sh\"" ;;
  Linux)  SL_CMD="bash \"$USER_DEST/statusline/statusline-command-linux.sh\"" ;;
  *) log "⚠ unknown OS — skipping statusline (Windows: wire the .ps1 manually, see statusline/README.md)" ;;
esac

# --- Helpers ---------------------------------------------------------------
ensure_json() { mkdir -p "$(dirname "$1")"; [[ -f "$1" ]] || echo '{}' > "$1"; }

copy_kit() { # copy_kit <dest> <extra rsync excludes...>
  local dest="$1"; shift
  mkdir -p "$dest"
  if have rsync; then
    rsync -a --exclude='.git' --exclude='.gitignore' --exclude='.DS_Store' \
      --exclude='settings.json' --exclude='settings.local.json' \
      --exclude='.kit-version' --exclude='.kit-manifest' "$@" "$KIT_DIR"/ "$dest"/
  else
    ( cd "$KIT_DIR" && find . -type f ! -path './.git/*' ! -name '.gitignore' ! -name '.DS_Store' \
        ! -name 'settings.json' ! -name 'settings.local.json' \
        ! -name '.kit-version' ! -name '.kit-manifest' -print0 \
      | while IFS= read -r -d '' f; do mkdir -p "$dest/$(dirname "$f")"; cp "$f" "$dest/$f"; done )
  fi
}

sync_manifest() { # sync_manifest <dest> <exclude_statusline:0|1>  — prune files the kit no longer ships
  local dest="$1" excl_sl="$2"
  local mf="$dest/.kit-manifest" newmf
  local prune=(! -path './.git/*' ! -name '.gitignore' ! -name '.DS_Store'
               ! -name 'settings.json' ! -name 'settings.local.json'
               ! -name '.kit-manifest' ! -name '.kit-version')
  [[ "$excl_sl" == 1 ]] && prune+=(! -path './statusline/*')
  newmf="$(cd "$KIT_DIR" && find . -type f "${prune[@]}" | sed 's|^\./||' | sort)"
  if [[ -f "$mf" ]]; then
    comm -23 "$mf" <(printf '%s\n' "$newmf") | while IFS= read -r rel; do
      [[ -n "$rel" && -e "$dest/$rel" ]] && { rm -f "$dest/$rel"; log "pruned (removed from kit): $rel"; }
    done
  fi
  printf '%s\n' "$newmf" > "$mf"
}

stamp_version() { # stamp_version <dest>
  local dest="$1" old=""
  [[ -f "$dest/.kit-version" ]] && old="$(cat "$dest/.kit-version")"
  printf '%s\n' "$KIT_VERSION" > "$dest/.kit-version"
  if [[ -z "$old" ]]; then log "version: $KIT_VERSION (fresh install)"
  elif [[ "$old" == "$KIT_VERSION" ]]; then log "version: $KIT_VERSION (unchanged)"
  else log "version: $old → $KIT_VERSION (updated)"; fi
}

ensure_hook() { # ensure_hook <settings_file> <hook_cmd>
  local f="$1" hook="$2" tmp; tmp="$(mktemp)"
  jq --arg hook "$hook" '
    .hooks = (.hooks // {}) | .hooks.PreToolUse = (.hooks.PreToolUse // [])
    | ([.hooks.PreToolUse[]?.hooks[]?.command] | map(select(. != null)) | any(test("delete-2fa.sh"))) as $has
    | if $has then . else .hooks.PreToolUse += [{matcher:"Bash",hooks:[{type:"command",command:$hook,timeout:10}]}] end
  ' "$f" > "$tmp" && mv "$tmp" "$f"
  log "ensured delete-2FA hook in $f"
}

set_statusline() { # set_statusline <settings_file> <cmd>
  local f="$1" cmd="$2" tmp setSL=true cur reply
  [[ -z "$cmd" ]] && return 0
  if [[ "$(jq 'has("statusLine")' "$f")" == "true" ]]; then
    cur="$(jq -r '.statusLine.command // "?"' "$f")"
    if [[ "${FORCE_STATUSLINE:-0}" == "1" ]]; then
      log "↻ replacing existing statusLine (FORCE_STATUSLINE=1)"
    elif [[ -t 0 ]]; then
      printf '  ⚠ Já existe uma statusLine em %s:\n      %s\n' "$f" "$cur"
      printf '    Substituir pela statusline do kit? [y/N] '
      read -r reply || reply=""
      case "$reply" in
        [yY]|[yY][eE][sS]|[sS]|[sS][iI][mM]) log "↻ replacing existing statusLine" ;;
        *) setSL=false; log "↺ kept existing statusLine" ;;
      esac
    else
      setSL=false; log "↺ kept existing statusLine (non-interactive; FORCE_STATUSLINE=1 to replace)"
    fi
  fi
  [[ "$setSL" == "true" ]] || return 0
  tmp="$(mktemp)"
  jq --arg cmd "$cmd" '.statusLine = {type:"command", command:$cmd}' "$f" > "$tmp" && mv "$tmp" "$f"
  log "set statusLine in $f"
}

gitignore_add() { # gitignore_add <repo_root> <entry>
  local gi="$1/.gitignore" entry="$2"
  if [[ -f "$gi" ]] && grep -qE "^${entry%/}/?\$" "$gi"; then
    log ".gitignore already ignores $entry"; return 0
  fi
  [[ -f "$gi" && -n "$(tail -c1 "$gi" 2>/dev/null)" ]] && printf '\n' >> "$gi"
  printf '%s\n' "$entry" >> "$gi"
  log "added $entry to $(basename "$1")/.gitignore"
}

# =============================================================================
if [[ "$HYBRID" == true ]]; then
  # --- PROJECT level: everything except statusline ---
  copy_kit "$PROJ_DEST" --exclude='statusline'
  [[ -f "$PROJ_DEST/settings.local.json" ]] || cp "$KIT_DIR/settings.local.json" "$PROJ_DEST/settings.local.json"
  ensure_json "$PROJ_DEST/settings.json"
  chmod +x "$PROJ_DEST"/hooks/*.sh 2>/dev/null || true
  ensure_hook "$PROJ_DEST/settings.json" "\$CLAUDE_PROJECT_DIR/.claude/hooks/delete-2fa.sh"
  sync_manifest "$PROJ_DEST" 1
  stamp_version "$PROJ_DEST"

  # --- USER level: statusline only ---
  mkdir -p "$USER_DEST/statusline"
  cp "$KIT_DIR"/statusline/* "$USER_DEST/statusline/" 2>/dev/null || true
  chmod +x "$USER_DEST"/statusline/*.sh 2>/dev/null || true
  ensure_json "$USER_DEST/settings.json"
  set_statusline "$USER_DEST/settings.json" "$SL_CMD"

  # --- Ignore .claude in the repo ---
  gitignore_add "$PROJECT" ".claude/"
else
  # --- GLOBAL: everything into the user dir ---
  copy_kit "$USER_DEST"
  [[ -f "$USER_DEST/settings.local.json" ]] || cp "$KIT_DIR/settings.local.json" "$USER_DEST/settings.local.json"
  ensure_json "$USER_DEST/settings.json"
  chmod +x "$USER_DEST"/hooks/*.sh "$USER_DEST"/statusline/*.sh 2>/dev/null || true
  ensure_hook "$USER_DEST/settings.json" "$USER_DEST/hooks/delete-2fa.sh"
  set_statusline "$USER_DEST/settings.json" "$SL_CMD"
  sync_manifest "$USER_DEST" 0
  stamp_version "$USER_DEST"
fi

echo "✓ Done."
echo
echo "Next steps:"
echo "  • Restart Claude Code so it picks up the new config."
[[ "$HYBRID" == true ]] && echo "  • Commands/agents/skills are in $PROJ_DEST (gitignored). Statusline is user-level."
echo "  • Durable docs (PRDs, plans, changelog) live at the repo root under docs/ — not in .claude/."
echo "  • Give the project a CLAUDE.md if it has none:  /claude-md create"
echo "  • Guides:  $([[ "$HYBRID" == true ]] && echo "$PROJ_DEST" || echo "$USER_DEST")/USAGE.md  ·  CONVENTIONS.md"
exit 0
