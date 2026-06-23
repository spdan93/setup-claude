#!/usr/bin/env pwsh
# =============================================================================
# Claude Code statusline — Windows (PowerShell 7+)
# Mirrors the macOS/Linux bash versions. No jq needed (uses ConvertFrom-Json).
# Wire it in settings.json:
#   "statusLine": { "type": "command",
#     "command": "pwsh -NoProfile -File \"%USERPROFILE%\\.claude\\statusline\\statusline-command-windows.ps1\"" }
# =============================================================================
$ErrorActionPreference = 'SilentlyContinue'

$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { return }

# --- Parse fields ---
$displayName  = $j.model.display_name
$ctxSize      = $j.context_window.context_window_size
$usedPct      = 0
if ($j.context_window.used_percentage) { $usedPct = [int][math]::Floor([double]$j.context_window.used_percentage) }
$cwd          = if ($j.workspace.current_dir) { $j.workspace.current_dir } else { $j.cwd }
$totalIn      = $j.context_window.total_input_tokens
$totalOut     = $j.context_window.total_output_tokens
$fiveHPct     = $j.rate_limits.five_hour.used_percentage
$fiveHReset   = $j.rate_limits.five_hour.resets_at
$sevenDPct    = $j.rate_limits.seven_day.used_percentage
$sevenDReset  = $j.rate_limits.seven_day.resets_at
$cost         = $j.cost.total_cost_usd
$durationMs   = $j.cost.total_duration_ms
$linesAdded   = $j.cost.total_lines_added
$linesRemoved = $j.cost.total_lines_removed

# --- Colors (ANSI; Windows Terminal supports these) ---
$e = [char]27
$R="$e[0m"; $C="$e[96m"; $B="$e[94m"; $Y="$e[93m"; $G="$e[92m"; $RD="$e[91m"; $M="$e[95m"; $W="$e[37m"; $SEP="$e[90m"

function ColorByPct([int]$v) { if ($v -ge 80) { $RD } elseif ($v -ge 50) { $Y } else { $G } }

function FmtTokens($t) {
  if ($null -eq $t -or $t -eq 0) { return '' }
  if ($t -ge 1000000) { return ('{0:N1}M' -f ($t / 1000000)) }
  elseif ($t -ge 1000) { return ('{0:N0}K' -f ($t / 1000)) }
  else { return "$t" }
}

function FmtDuration($ms) {
  $s = [math]::Floor($ms / 1000); $m = [math]::Floor($s / 60); $h = [math]::Floor($m / 60)
  if ($h -gt 0) { '{0}h{1:D2}m' -f $h, ($m % 60) }
  elseif ($m -gt 0) { '{0}m{1:D2}s' -f $m, ($s % 60) }
  else { "${s}s" }
}

function FmtRemaining($resetsAt) {
  if (-not $resetsAt) { return '' }
  $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $rem = [int64]$resetsAt - $now
  if ($rem -le 0) { return 'now' }
  $d = [math]::Floor($rem / 86400); $h = [math]::Floor(($rem % 86400) / 3600); $m = [math]::Floor(($rem % 3600) / 60)
  if ($d -gt 0) { '{0}d{1}h' -f $d, $h }
  elseif ($h -gt 0) { '{0}h{1:D2}m' -f $h, $m }
  else { "${m}m" }
}

# --- Model tag: Opus(1M), Sonnet, Haiku ---
$modelBase = ($displayName -split ' ')[0]
$modelTag = $modelBase
if ($ctxSize -and [int64]$ctxSize -ge 1000000) { $modelTag = "$modelBase(1M)" }
$dirName = if ($cwd) { Split-Path $cwd -Leaf } else { '' }

# --- Git branch + status (cached 5s) ---
$gitBranch = ''; $gitStaged = 0; $gitModified = 0; $repoUrl = ''
$cache = Join-Path $env:TEMP 'statusline-git-cache'
$linkCache = Join-Path $env:TEMP 'statusline-repo-link'
if ($cwd -and (Test-Path $cwd)) {
  $stale = $true
  if (Test-Path $cache) {
    if (((Get-Date) - (Get-Item $cache).LastWriteTime).TotalSeconds -le 5) { $stale = $false }
  }
  if ($stale) {
    Push-Location $cwd
    if (git rev-parse --git-dir 2>$null) {
      $br = (git --no-optional-locks symbolic-ref --short HEAD 2>$null)
      $st = @(git --no-optional-locks diff --cached --numstat 2>$null).Count
      $md = @(git --no-optional-locks diff --numstat 2>$null).Count
      "$br|$st|$md" | Set-Content -NoNewline $cache
    } else { "||" | Set-Content -NoNewline $cache }
    Pop-Location
  }
  $parts = (Get-Content $cache 2>$null) -split '\|'
  $gitBranch = $parts[0]; $gitStaged = [int]($parts[1]); $gitModified = [int]($parts[2])

  # Repo link (cached 30s)
  $linkStale = $true
  if (Test-Path $linkCache) {
    if (((Get-Date) - (Get-Item $linkCache).LastWriteTime).TotalSeconds -le 30) { $linkStale = $false }
  }
  if ($linkStale) {
    Push-Location $cwd
    $u = (git remote get-url origin 2>$null)
    if ($u) { $u = ($u -replace 'git@github.com:', 'https://github.com/') -replace '\.git$', '' }
    "$u" | Set-Content -NoNewline $linkCache
    Pop-Location
  }
  $repoUrl = (Get-Content $linkCache 2>$null)
}

# --- Context bar ---
$barColor = ColorByPct $usedPct
$filled = [math]::Floor($usedPct * 10 / 100); $empty = 10 - $filled
$bar = ('▓' * $filled) + ('░' * $empty)

# --- Line 1: [Model] dir | $cost | duration | tokens ---
$line1 = "$C[$modelTag]$R $W$dirName$R"
if ($cost -and $cost -ne 0) { $line1 += " $SEP|$R $M`$$('{0:N2}' -f [double]$cost)$R" }
if ($durationMs -and $durationMs -gt 0) { $line1 += " $SEP|$R ${W}*$R $C$(FmtDuration $durationMs)$R" }
if ($totalIn -and $totalOut) { $line1 += " $SEP|$R $W v$(FmtTokens $totalIn) ^$(FmtTokens $totalOut)$R" }

# --- Line 2: bar % | 5h X% | 7d X% ---
$line2 = "$barColor$bar$R $W$usedPct%$R"
if ($fiveHPct) {
  $fh = [int][math]::Round([double]$fiveHPct)
  $line2 += " $SEP|$R ${W}5h$R $(ColorByPct $fh)$fh%$R"
  if ($fiveHReset) { $line2 += " $W~$(FmtRemaining $fiveHReset)$R" }
}
if ($sevenDPct) {
  $sd = [int][math]::Round([double]$sevenDPct)
  $line2 += " $SEP|$R ${W}7d$R $(ColorByPct $sd)$sd%$R"
  if ($sevenDReset) { $line2 += " $W~$(FmtRemaining $sevenDReset)$R" }
}

# --- Line 3: git:(branch) +staged ~modified | repo | +lines -lines ---
$line3 = ''
if ($gitBranch) {
  $line3 = "${W}git:($R$B$gitBranch$R$W)$R"
  if ($gitStaged -gt 0) { $line3 += " $G+$gitStaged$R" }
  if ($gitModified -gt 0) { $line3 += " $Y~$gitModified$R" }
}
if ($repoUrl) {
  $repoName = Split-Path $repoUrl -Leaf
  if ($line3) { $line3 += " $SEP|$R " }
  $line3 += "$W$repoName$R"
}
if (($linesAdded -and $linesAdded -gt 0) -or ($linesRemoved -and $linesRemoved -gt 0)) {
  $la = if ($linesAdded) { $linesAdded } else { 0 }
  $lr = if ($linesRemoved) { $linesRemoved } else { 0 }
  if ($line3) { $line3 += " $SEP|$R " }
  $line3 += "$G+$la$R $RD-$lr$R"
}

Write-Output $line1
Write-Output $line2
Write-Host -NoNewline $line3
