#!/bin/bash
# =============================================================================
# Delete 2FA Guard Hook (PreToolUse)
# =============================================================================
# Blocks destructive delete commands (rm, rmdir, etc) and requires 2-factor
# authentication from the user before proceeding.
#
# Flow:
# 1. Detect destructive command → check if user recently confirmed
# 2. If confirmed within last 60 seconds → allow
# 3. If not confirmed → block via JSON output and request confirmation
# 4. User confirms "CONFIRMO DELETE" → /confirm-delete updates state
# 5. User re-runs command → hook allows it
#
# Output Format (exit 0 with JSON):
# - permissionDecision: "deny" blocks the tool
# - permissionDecisionReason: shown to Claude
# =============================================================================

# Read input from stdin (Claude Code passes tool call as JSON)
input="$(cat)"

# Extract tool name and command
tool="$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null || echo "")"
cmd="$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")"

# Only guard Bash tool
if [[ "$tool" != "Bash" ]]; then
  exit 0
fi

# Skip if no command
if [[ -z "$cmd" ]]; then
  exit 0
fi

# =============================================================================
# Detect destructive delete patterns
# =============================================================================

destructive_pattern='(^|[;&|]|&&|\|\||[[:space:]])(rm[[:space:]]|rmdir[[:space:]]|del[[:space:]]|erase[[:space:]]|trash[[:space:]]|trash-put[[:space:]]|remove-item[[:space:]]|git[[:space:]]+rm[[:space:]])'
find_delete_pattern='find[[:space:]].*-delete'

is_destructive=false
if echo "$cmd" | grep -qEi "$destructive_pattern"; then
  is_destructive=true
fi
if echo "$cmd" | grep -qEi "$find_delete_pattern"; then
  is_destructive=true
fi

# If not destructive, allow
if [[ "$is_destructive" != "true" ]]; then
  exit 0
fi

# =============================================================================
# Allow safe operations
# =============================================================================

# Allow dry-run operations
if echo "$cmd" | grep -qE '\-\-dry\-run|\-n[[:space:]]'; then
  exit 0
fi

# Allow help commands
if echo "$cmd" | grep -qE '\-\-help|\-h[[:space:]]'; then
  exit 0
fi

# =============================================================================
# Check for recent user confirmation (time-based 2FA)
# =============================================================================

state_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude"
state_file="$state_dir/.delete-2fa-state.json"

# Check if user confirmed recently (within 60 seconds)
if [[ -f "$state_file" ]]; then
  confirmed_at="$(jq -r '.confirmed_at // 0' "$state_file" 2>/dev/null || echo "0")"
  now="$(date +%s)"
  elapsed=$((now - confirmed_at))

  # If confirmed within last 60 seconds, allow ALL destructive commands
  if [[ $elapsed -lt 60 ]]; then
    exit 0
  fi
fi

# =============================================================================
# Block and request confirmation via JSON output
# =============================================================================

# Ensure state directory exists
mkdir -p "$state_dir" 2>/dev/null || true

# Generate token for display (informational only)
token="$(openssl rand -hex 3 2>/dev/null || head -c 6 /dev/urandom | xxd -p)"

# Save pending state (NOT confirmed yet)
cat > "$state_file" << EOF
{
  "status": "pending",
  "token": "$token",
  "command_preview": "$(echo "$cmd" | head -c 500 | tr '\n' ' ' | sed 's/"/\\"/g')",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "confirmed_at": 0
}
EOF

# Output JSON to deny the tool call (exit 0 with JSON)
# This is the correct format per Claude Code hooks documentation
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "⚠️ DELETE GUARD (2FA) ⚠️\n\nComando destrutivo detectado:\n${cmd}\n\nPara prosseguir:\n1. Peça confirmação ao usuário: 'CONFIRMO DELETE'\n2. Após confirmação, execute: /confirm-delete\n3. Re-execute o comando original\n\nToken: ${token}"
  }
}
EOF

exit 0
