# =============================================================================
# Claude Code kit installer — Windows (Windows PowerShell 5.1+ or PowerShell 7+)
# =============================================================================
# Native Windows counterpart of install.sh. Runs on the built-in Windows
# PowerShell 5.1 (`powershell`) — PowerShell 7 (`pwsh`) is NOT required.
# Idempotent and non-destructive: never deletes your files, never clobbers an
# existing settings.json (merges), asks before replacing an existing statusLine.
#
# Layout (hybrid, same as install.sh):
#   * Statusline       -> USER level  (~/.claude)          — same in every project
#   * Commands/agents/
#     skills/hook/etc. -> PROJECT level (<repo>\.claude)   — local to the repo
#   * <repo>\.claude   -> added to <repo>\.gitignore
#   * Durable docs (PRDs, plans, changelog) live OUTSIDE .claude, at the repo root.
#
# Usage (from Windows PowerShell or pwsh):
#   powershell -ExecutionPolicy Bypass -File .\install.ps1                    # current repo
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 C:\path\to\repo    # another repo
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Global            # ~/.claude only
#
# Env:
#   CLAUDE_CONFIG_DIR   user config dir (default ~/.claude)
#   FORCE_STATUSLINE=1  replace an existing statusLine without asking
#
# Requires: git recommended. No jq needed (uses PowerShell's JSON).
# Note: the delete-2FA hook is a bash script; on Windows it only fires if a bash
#       (e.g. Git Bash) is available to Claude Code. The rest works without bash.
# =============================================================================
[CmdletBinding()]
param(
    [string]$Project = (Get-Location).Path,
    [switch]$Global
)
$ErrorActionPreference = 'Stop'

$KitDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- JSON helpers (work on both Windows PowerShell 5.1 and PowerShell 7) -----
function ConvertTo-HashtableDeep($obj) {
    if ($null -eq $obj) { return $null }
    if ($obj -is [System.Management.Automation.PSCustomObject]) {
        $h = @{}
        foreach ($p in $obj.PSObject.Properties) { $h[$p.Name] = ConvertTo-HashtableDeep $p.Value }
        return $h
    }
    if ($obj -is [System.Collections.IDictionary]) {
        $h = @{}
        foreach ($k in @($obj.Keys)) { $h[$k] = ConvertTo-HashtableDeep $obj[$k] }
        return $h
    }
    if ($obj -is [string]) { return $obj }
    if ($obj -is [System.Collections.IEnumerable]) {
        return @($obj | ForEach-Object { ConvertTo-HashtableDeep $_ })
    }
    return $obj
}

function Read-JsonAsHashtable($path) {
    $raw = Get-Content $path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { return @{} }
    $h = ConvertTo-HashtableDeep ($raw | ConvertFrom-Json)
    if ($h -isnot [System.Collections.IDictionary]) { return @{} }
    return $h
}

# Write UTF-8 WITHOUT BOM (Windows PowerShell 5.1's Set-Content -Encoding utf8
# adds a BOM, which can break JSON parsing).
function Write-Utf8NoBom($path, $content) {
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
}

# --- Version stamp ---------------------------------------------------------
$KitVersion = (Get-Content (Join-Path $KitDir 'VERSION') -ErrorAction SilentlyContinue | Select-Object -First 1)
if (-not $KitVersion) { $KitVersion = 'unknown' }
try {
    $sha = (& git -C $KitDir rev-parse --short HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $sha) { $KitVersion = "$KitVersion+$sha" }
} catch {}

# --- Resolve targets -------------------------------------------------------
$UserDest = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
if (-not (Test-Path $Project)) { Write-Error "Target dir not found: $Project"; exit 1 }
$ProjectFull = (Resolve-Path $Project).Path
$ProjDest = Join-Path $ProjectFull '.claude'
$Hybrid = -not ($Global.IsPresent -or ($ProjDest -eq $UserDest))

function Log($m) { Write-Host "  $m" }
Write-Host "> Installing Claude Code kit $KitVersion ($(if ($Hybrid) { 'hybrid' } else { 'global' }))"
Log "kit:  $KitDir"
Log "user: $UserDest"
if ($Hybrid) { Log "project: $ProjDest" }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Log "! git not found — the changelog/commit features need it"
}

# --- Statusline command (use pwsh if available, else Windows PowerShell) -----
$SlInterp = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$SlCmd = "$SlInterp -NoProfile -File `"$UserDest\statusline\statusline-command-windows.ps1`""

# --- Helpers ---------------------------------------------------------------
function Ensure-Dir($path) { if (-not (Test-Path $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null } }

function Ensure-Json($path) {
    Ensure-Dir (Split-Path -Parent $path)
    if (-not (Test-Path $path)) { Write-Utf8NoBom $path '{}' }
}

$ExcludeNames = @('.gitignore', '.DS_Store', 'settings.json', 'settings.local.json', '.kit-version', '.kit-manifest')

function Kit-Files($excludeStatusline) {
    Get-ChildItem -Path $KitDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($KitDir.Length).TrimStart('\', '/')
        if ($rel -like '.git*') { return }
        if ($ExcludeNames -contains $_.Name) { return }
        $top = ($rel -split '[\\/]')[0]
        if ($excludeStatusline -and $top -eq 'statusline') { return }
        $rel -replace '\\', '/'
    }
}

function Copy-Kit($dest, $excludeStatusline) {
    Ensure-Dir $dest
    foreach ($rel in (Kit-Files $excludeStatusline)) {
        $src = Join-Path $KitDir ($rel -replace '/', '\')
        $tgt = Join-Path $dest ($rel -replace '/', '\')
        Ensure-Dir (Split-Path -Parent $tgt)
        Copy-Item $src $tgt -Force
    }
}

function Ensure-Hook($settingsPath, $hookCmd) {
    $j = Read-JsonAsHashtable $settingsPath
    if (-not $j.ContainsKey('hooks')) { $j['hooks'] = @{} }
    if (-not $j['hooks'].ContainsKey('PreToolUse')) { $j['hooks']['PreToolUse'] = @() }
    $has = $false
    foreach ($entry in @($j['hooks']['PreToolUse'])) {
        foreach ($h in @($entry['hooks'])) {
            if ($h['command'] -and ($h['command'] -like '*delete-2fa.sh*')) { $has = $true }
        }
    }
    if (-not $has) {
        $newEntry = @{ matcher = 'Bash'; hooks = @(@{ type = 'command'; command = $hookCmd; timeout = 10 }) }
        $j['hooks']['PreToolUse'] = @($j['hooks']['PreToolUse']) + @($newEntry)
    }
    Write-Utf8NoBom $settingsPath ($j | ConvertTo-Json -Depth 20)
    Log "ensured delete-2FA hook in $settingsPath"
}

function Set-Statusline($settingsPath, $cmd) {
    if (-not $cmd) { return }
    $j = Read-JsonAsHashtable $settingsPath
    $set = $true
    if ($j.ContainsKey('statusLine')) {
        $cur = $j['statusLine']['command']
        if ($env:FORCE_STATUSLINE -eq '1') {
            Log "replacing existing statusLine (FORCE_STATUSLINE=1)"
        }
        elseif ([Environment]::UserInteractive) {
            Write-Host "  ! A statusLine is already configured:"
            Write-Host "      $cur"
            $ans = Read-Host "    Replace it with this kit's statusline? [y/N]"
            if ($ans -notmatch '^(y|yes|s|sim)$') { $set = $false; Log "kept existing statusLine" }
        }
        else {
            $set = $false
            Log "kept existing statusLine (non-interactive; set FORCE_STATUSLINE=1 to replace)"
        }
    }
    if ($set) {
        $j['statusLine'] = @{ type = 'command'; command = $cmd }
        Write-Utf8NoBom $settingsPath ($j | ConvertTo-Json -Depth 20)
        Log "set statusLine in $settingsPath"
    }
}

function Gitignore-Add($repoRoot, $entry) {
    $gi = Join-Path $repoRoot '.gitignore'
    if (Test-Path $gi) {
        foreach ($line in (Get-Content $gi)) {
            if ($line.Trim().TrimEnd('/') -eq $entry.TrimEnd('/')) { Log ".gitignore already ignores $entry"; return }
        }
    }
    Add-Content -Path $gi -Value $entry
    Log "added $entry to .gitignore"
}

function Sync-Manifest($dest, $excludeStatusline) {
    $mf = Join-Path $dest '.kit-manifest'
    $new = @(Kit-Files $excludeStatusline | Sort-Object)
    if (Test-Path $mf) {
        foreach ($rel in (Get-Content $mf)) {
            if ($new -notcontains $rel) {
                $p = Join-Path $dest ($rel -replace '/', '\')
                if (Test-Path $p) { Remove-Item $p -Force; Log "pruned (removed from kit): $rel" }
            }
        }
    }
    Write-Utf8NoBom $mf (($new -join "`n") + "`n")
}

function Stamp-Version($dest) {
    $vf = Join-Path $dest '.kit-version'
    $old = if (Test-Path $vf) { (Get-Content $vf -Raw).Trim() } else { '' }
    Write-Utf8NoBom $vf ($KitVersion + "`n")
    if (-not $old) { Log "version: $KitVersion (fresh install)" }
    elseif ($old -eq $KitVersion) { Log "version: $KitVersion (unchanged)" }
    else { Log "version: $old -> $KitVersion (updated)" }
}

# =============================================================================
if ($Hybrid) {
    # --- PROJECT level: everything except statusline ---
    Copy-Kit $ProjDest $true
    $slj = Join-Path $ProjDest 'settings.local.json'
    if (-not (Test-Path $slj)) { Copy-Item (Join-Path $KitDir 'settings.local.json') $slj }
    Ensure-Json (Join-Path $ProjDest 'settings.json')
    Ensure-Hook (Join-Path $ProjDest 'settings.json') '$CLAUDE_PROJECT_DIR/.claude/hooks/delete-2fa.sh'
    Sync-Manifest $ProjDest $true
    Stamp-Version $ProjDest

    # --- USER level: statusline only ---
    Ensure-Dir (Join-Path $UserDest 'statusline')
    Get-ChildItem (Join-Path $KitDir 'statusline') -File | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $UserDest ('statusline\' + $_.Name)) -Force
    }
    Ensure-Json (Join-Path $UserDest 'settings.json')
    Set-Statusline (Join-Path $UserDest 'settings.json') $SlCmd

    Gitignore-Add $ProjectFull '.claude/'
}
else {
    # --- GLOBAL: everything into the user dir ---
    Copy-Kit $UserDest $false
    $slj = Join-Path $UserDest 'settings.local.json'
    if (-not (Test-Path $slj)) { Copy-Item (Join-Path $KitDir 'settings.local.json') $slj }
    Ensure-Json (Join-Path $UserDest 'settings.json')
    Ensure-Hook (Join-Path $UserDest 'settings.json') "$UserDest\hooks\delete-2fa.sh"
    Set-Statusline (Join-Path $UserDest 'settings.json') $SlCmd
    Sync-Manifest $UserDest $false
    Stamp-Version $UserDest
}

Write-Host "OK Done."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  * Restart Claude Code so it picks up the new config."
if ($Hybrid) { Write-Host "  * Commands/agents/skills are in $ProjDest (gitignored). Statusline is user-level." }
Write-Host "  * Durable docs (PRDs, plans, changelog) live at the repo root under docs\ — not in .claude\."
Write-Host "  * The delete-2FA hook is a bash script; it fires only if a bash (Git Bash) is available."
Write-Host "  * Guides:  $(if ($Hybrid) { $ProjDest } else { $UserDest })\USAGE.md  ·  CONVENTIONS.md"
