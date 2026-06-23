#!/usr/bin/env bash
input=$(cat)

# Parse JSON
display_name=$(echo "$input" | jq -r '.model.display_name // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

# Rate limits
five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_d_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Cost & duration
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

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
    age=$(( $(date +%s) - $(stat -f %m "$CACHE" 2>/dev/null || echo 0) ))
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
    age=$(( $(date +%s) - $(stat -f %m "$LINK_CACHE" 2>/dev/null || echo 0) ))
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

# Format tokens: 1234567 → 1.2M, 12345 → 12K
fmt_tokens() {
  local t=$1
  [ -z "$t" ] || [ "$t" = "null" ] && return
  if [ "$t" -ge 1000000 ] 2>/dev/null; then
    printf "%.1fM" "$(echo "$t / 1000000" | bc -l)"
  elif [ "$t" -ge 1000 ] 2>/dev/null; then
    printf "%.0fK" "$(echo "$t / 1000" | bc -l)"
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
