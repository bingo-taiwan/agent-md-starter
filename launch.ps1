# launch.ps1 - 列出 ~\Projects 底下所有專案的交接檔，選一個就 cd 進去啟動 agent。
# 用法：powershell -ExecutionPolicy Bypass -File .\launch.ps1 [-Agent agy|claude|copilot] [-Root C:\path] [-SkipPermissions] [-DryRun]
# 檔案為 UTF-8 with BOM，Windows PowerShell 5.1 才能正確讀中文。
param(
  [ValidateSet('agy','claude','copilot')][string]$Agent = 'agy',
  [string]$Root = (Join-Path $HOME 'Projects'),
  [switch]$DryRun,
  [switch]$SkipPermissions
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$items = @(Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $h = Join-Path $_.FullName 'docs\handoff.md'
  if (Test-Path $h) {
    $txt = Get-Content $h -Raw -Encoding UTF8
    $updated = if ($txt -match '(?m)^updated:\s*(.+)$') { $Matches[1].Trim() } else { '' }
    $status  = if ($txt -match '(?s)## 目前狀態\s*\n-\s*([^\n]+)') { $Matches[1].Trim() } else { '' }
    [pscustomobject]@{ Name = $_.Name; Dir = $_.FullName; Updated = $updated; Status = $status }
  }
} | Sort-Object Updated -Descending)

Write-Host ''
Write-Host "=== 專案交接檔（$Root）===" -ForegroundColor Cyan
if (-not $items) { Write-Host '  （沒有任何專案有 docs\handoff.md）' -ForegroundColor Yellow }
$i = 1
foreach ($it in $items) {
  $s = if ($it.Status.Length -gt 60) { $it.Status.Substring(0,60) + '…' } else { $it.Status }
  Write-Host ("  {0,2}. {1,-24} {2,-16} {3}" -f $i, $it.Name, $it.Updated, $s)
  $i++
}
Write-Host '   0. 不選，直接在 Projects 根目錄啟動'
$pick = Read-Host '選擇'
$target = $Root
if ($pick -match '^\d+$' -and [int]$pick -ge 1 -and [int]$pick -le $items.Count) { $target = $items[[int]$pick - 1].Dir }

Set-Location $target
Write-Host "-> $target" -ForegroundColor Green
if ($DryRun) { return }
switch ($Agent) {
  'agy'     { if ($SkipPermissions) { & agy --dangerously-skip-permissions } else { & agy } }
  'claude'  { if ($SkipPermissions) { & claude --dangerously-skip-permissions } else { & claude } }
  'copilot' { & copilot }
}
