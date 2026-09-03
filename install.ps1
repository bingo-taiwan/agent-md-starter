# Install AGENTS.md as user-level instructions for each CLI, plus the handoff skill and Claude hook.
# ASCII only: .ps1 with CJK breaks the Windows PowerShell 5.1 parser.
# Usage:  powershell -ExecutionPolicy Bypass -File .\install.ps1
$src = Join-Path $PSScriptRoot 'AGENTS.md'
$targets = @(
  (Join-Path $HOME '.claude\CLAUDE.md'),
  (Join-Path $HOME '.gemini\GEMINI.md'),
  (Join-Path $HOME '.copilot\copilot-instructions.md')
)
foreach ($t in $targets) {
  New-Item -ItemType Directory -Force -Path (Split-Path $t) | Out-Null
  if (Test-Path $t) { Copy-Item $t "$t.bak" -Force }
  Copy-Item $src $t -Force
  Write-Host "installed -> $t"
}

# handoff skill: Claude Code reads ~/.claude/skills/<name>/SKILL.md, Antigravity CLI (agy) reads ~/.gemini/config/skills/<name>/SKILL.md
$skillSrc = Join-Path $PSScriptRoot 'skills\handoff'
foreach ($d in @((Join-Path $HOME '.claude\skills\handoff'), (Join-Path $HOME '.gemini\config\skills\handoff'))) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  Copy-Item (Join-Path $skillSrc '*') $d -Recurse -Force
  Write-Host "installed -> $d"
}

# Claude Code SessionStart hook (script only; merge hooks\claude-settings-snippet.json into ~/.claude/settings.json yourself)
$hookDir = Join-Path $HOME '.claude\hooks'
New-Item -ItemType Directory -Force -Path $hookDir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'hooks\handoff-loader.sh') $hookDir -Force
Write-Host "installed -> $hookDir\handoff-loader.sh  (add SessionStart hook: see hooks\claude-settings-snippet.json)"
