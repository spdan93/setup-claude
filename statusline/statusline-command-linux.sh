#!/usr/bin/env bash
input=$(cat)

# --- Parse JSON: jq -> python3 -> (degrada vazio). NÃO exige jq. -------------
if command -v jq >/dev/null 2>&1; then JSON_TOOL=jq
elif command -v python3 >/dev/null 2>&1; then JSON_TOOL=python3
elif command -v python >/dev/null 2>&1; then JSON_TOOL=python
else JSON_TOOL=none; fi

emit_fields() {
  case "$JSON_TOOL" in
    jq)
      printf '%s' "$input" | jq -r '
        .model.display_name // "",
        .context_window.context_window_size // "",
        (.context_window.used_percentage // 0),
        (.workspace.current_dir // .cwd // ""),
        .context_window.total_input_tokens // "",
        .context_window.total_output_tokens // "",
        .rate_limits.five_hour.used_percentage // "",
        .rate_limits.five_hour.resets_at // "",
        .rate_limits.seven_day.used_percentage // "",
        .rate_limits.seven_day.resets_at // "",
        .cost.total_cost_usd // "",
        .cost.total_duration_ms // "",
        .cost.total_lines_added // "",
        .cost.total_lines_removed // ""
      ' ;;
    python3|python)
      printf '%s' "$input" | "$JSON_TOOL" -c '
import json, sys
try: d = json.load(sys.stdin)
except Exception: d = {}
def gp(path, default=""):
    x = d
    for k in path.split("."):
        if isinstance(x, dict) and x.get(k) is not None: x = x[k]
        else: return default
    return x
cwd = gp("workspace.current_dir") or gp("cwd") or ""
for v in [gp("model.display_name"), gp("context_window.context_window_size"),
          gp("context_window.used_percentage", 0), cwd,
          gp("context_window.total_input_tokens"), gp("context_window.total_output_tokens"),
          gp("rate_limits.five_hour.used_percentage"), gp("rate_limits.five_hour.resets_at"),
          gp("rate_limits.seven_day.used_percentage"), gp("rate_limits.seven_day.resets_at"),
          gp("cost.total_cost_usd"), gp("cost.total_duration_ms"),
          gp("cost.total_lines_added"), gp("cost.total_lines_removed")]:
    print("" if v is None else v)
' ;;
    *) for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do echo ""; done ;;
  esac
}

{
  IFS= read -r display_name
  IFS= read -r ctx_size
  IFS= read -r used_pct
  IFS= read -r cwd
  IFS= read -r total_in
  IFS= read -r total_out
  IFS= read -r five_h_pct
  IFS= read -r five_h_resets
  IFS= read -r seven_d_pct
  IFS= read -r seven_d_resets
  IFS= read -r cost
  IFS= read -r duration_ms
  IFS= read -r lines_added
  IFS= read -r lines_removed
} < <(emit_fields)
used_pct=$(printf '%s' "${used_pct:-0}" | cut -d. -f1); [ -z "$used_pct" ] && used_pct=0

# Model tag: Opus(1M), Sonnet, Haiku
model_base=$(echo "$display_name" | awk '{print $1}')
model_tag="$model_base"
if [ -n "$ctx_size" ] && [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
  model_tag="${model_base}(1M)"
fi

# Directory
dir_name=$(basename "$cwd")

# Git branch + status (cached 5s)
CACHE="/tmp/statusline-git-cache"
git_branch=""; git_staged=0; git_modified=0
if [ -n "$cwd" ]; then
  stale=1
  if [ -f "$CACHE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
    [ "$age" -le 5 ] && stale=0
  fi
  if [ "$stale" -eq 1 ]; then
    if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
      branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
      staged=$(git -C "$cwd" --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
      modified=$(git -C "$cwd" --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')
      echo "${branch}|${staged}|${modified}" > "$CACHE"
    else
      echo "||" > "$CACHE"
    fi
  fi
  IFS='|' read -r git_branch git_staged git_modified < "$CACHE"
fi

# Repo link (cached 30s)
LINK_CACHE="/tmp/statusline-repo-link"
repo_url=""
if [ -n "$cwd" ]; then
  link_stale=1
  if [ -f "$LINK_CACHE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$LINK_CACHE" 2>/dev/null || echo 0) ))
    [ "$age" -le 30 ] && link_stale=0
  fi
  if [ "$link_stale" -eq 1 ]; then
    url=$(git -C "$cwd" remote get-url origin 2>/dev/null | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
    echo "$url" > "$LINK_CACHE"
  fi
  repo_url=$(cat "$LINK_CACHE" 2>/dev/null)
fi

# Colors (bright - visible on dark bg)
R="\033[0m"
C="\033[96m"          # bright cyan
B="\033[94m"          # bright blue
Y="\033[93m"          # bright yellow
G="\033[92m"          # bright green
RD="\033[91m"         # bright red
M="\033[95m"          # bright magenta
W="\033[37m"          # white - labels
SEP="\033[90m"        # dark gray - separators

color_by_pct() {
  local v=$1
  if [ "$v" -ge 80 ] 2>/dev/null; then printf "$RD"
  elif [ "$v" -ge 50 ] 2>/dev/null; then printf "$Y"
  else printf "$G"; fi
}

# Format tokens: 1234567 → 1.2M, 12345 → 12K  (aritmética pura, sem bc)
fmt_tokens() {
  local t=$1
  [ -z "$t" ] || [ "$t" = "null" ] && return
  if [ "$t" -ge 1000000 ] 2>/dev/null; then
    printf "%d.%dM" $((t / 1000000)) $(((t % 1000000) / 100000))
  elif [ "$t" -ge 1000 ] 2>/dev/null; then
    printf "%dK" $((t / 1000))
  else
    printf "%d" "$t"
  fi
}

# Format duration: ms → Xh Ym or Ym Zs
fmt_duration() {
  local ms=$1 s m h
  s=$((ms / 1000)); m=$((s / 60)); h=$((m / 60))
  if [ "$h" -gt 0 ]; then printf "%dh%02dm" "$h" $((m % 60))
  elif [ "$m" -gt 0 ]; then printf "%dm%02ds" "$m" $((s % 60))
  else printf "%ds" "$s"; fi
}

# Time remaining
fmt_remaining() {
  local resets_at=$1 now rem h m d
  now=$(date +%s); rem=$((resets_at - now))
  [ "$rem" -le 0 ] && { printf "now"; return; }
  d=$((rem / 86400)); h=$(( (rem % 86400) / 3600 )); m=$(( (rem % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then printf "%dd%dh" "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf "%dh%02dm" "$h" "$m"
  else printf "%dm" "$m"; fi
}

# Context bar
BAR_COLOR=$(color_by_pct "$used_pct")
FILLED=$((used_pct * 10 / 100)); EMPTY=$((10 - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v F "%${FILLED}s" && BAR="${F// /▓}"
[ "$EMPTY" -gt 0 ] && printf -v P "%${EMPTY}s" && BAR="${BAR}${P// /░}"

# === Line 1: [Model] dir │ $cost │ ⏱ duration │ tokens ===
line1="${C}[${model_tag}]${R} ${W}${dir_name}${R}"

if [ -n "$cost" ] && [ "$cost" != "0" ]; then
  cost_fmt=$(printf '$%.2f' "$cost")
  line1="${line1} ${SEP}│${R} ${M}${cost_fmt}${R}"
fi

if [ -n "$duration_ms" ] && [ "$duration_ms" -gt 0 ] 2>/dev/null; then
  line1="${line1} ${SEP}│${R} ${W}⏱${R} ${C}$(fmt_duration "$duration_ms")${R}"
fi

if [ -n "$total_in" ] && [ -n "$total_out" ]; then
  line1="${line1} ${SEP}│${R} ${W}↓$(fmt_tokens "$total_in") ↑$(fmt_tokens "$total_out")${R}"
fi

# === Line 2: bar % │ 5h X% ↻T │ 7d X% ↻T ===
line2="${BAR_COLOR}${BAR}${R} ${W}${used_pct}%${R}"

if [ -n "$five_h_pct" ]; then
  fh=$(printf '%.0f' "$five_h_pct")
  FC=$(color_by_pct "$fh")
  line2="${line2} ${SEP}│${R} ${W}5h${R} ${FC}${fh}%${R}"
  [ -n "$five_h_resets" ] && line2="${line2} ${W}↻$(fmt_remaining "$five_h_resets")${R}"
fi

if [ -n "$seven_d_pct" ]; then
  sd=$(printf '%.0f' "$seven_d_pct")
  SC=$(color_by_pct "$sd")
  line2="${line2} ${SEP}│${R} ${W}7d${R} ${SC}${sd}%${R}"
  [ -n "$seven_d_resets" ] && line2="${line2} ${W}↻$(fmt_remaining "$seven_d_resets")${R}"
fi

# === Line 3: git:(branch) +staged ~modified │ repo-link │ +lines -lines ===
line3=""
if [ -n "$git_branch" ]; then
  line3="${W}git:(${R}${B}${git_branch}${R}${W})${R}"
  [ "$git_staged" -gt 0 ] 2>/dev/null && line3="${line3} ${G}+${git_staged}${R}"
  [ "$git_modified" -gt 0 ] 2>/dev/null && line3="${line3} ${Y}~${git_modified}${R}"
fi

if [ -n "$repo_url" ]; then
  repo_name=$(basename "$repo_url")
  [ -n "$line3" ] && line3="${line3} ${SEP}│${R} " || line3=""
  line3="${line3}\033]8;;${repo_url}\a${W}${repo_name}${R}\033]8;;\a"
fi

if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
  la=${lines_added:-0}; lr=${lines_removed:-0}
  if [ "$la" -gt 0 ] 2>/dev/null || [ "$lr" -gt 0 ] 2>/dev/null; then
    [ -n "$line3" ] && line3="${line3} ${SEP}│${R} "
    line3="${line3}${G}+${la}${R} ${RD}-${lr}${R}"
  fi
fi

printf "%b\n" "$line1"
printf "%b\n" "$line2"
printf "%b" "$line3"
