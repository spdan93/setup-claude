---
name: confirm-delete
description: Confirms pending delete operation (2FA)
---

# Confirm Delete

The user has confirmed the pending delete operation with "CONFIRMO DELETE".

Update the state file to allow the delete command to proceed:

```bash
state_file="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/.delete-2fa-state.json"
now=$(date +%s)
jq --argjson ts "$now" '.confirmed_at = $ts | .status = "confirmed"' "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
echo "✓ Delete confirmado. Você tem 60 segundos para executar comandos destrutivos."
```

After running this, immediately re-execute the original delete command that was blocked.
