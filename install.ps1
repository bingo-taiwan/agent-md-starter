# Copy AGENTS.md to the user-level config of each CLI (ASCII only: .ps1 with CJK breaks the parser).
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
