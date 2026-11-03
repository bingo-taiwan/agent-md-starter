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

# 管理員身分警告：避免寫出 BUILTIN\Administrators + NULL SID DENY 的鎖死檔案，以及 agy -p 空輸出問題
try {
  $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if ($isAdmin) {
    Write-Host '[!] 警告：目前在「系統管理員」終端機執行！這可能導致對話紀錄檔權限鎖死（Access denied）或 agy -p 空輸出。建議改用一般權限啟動。' -ForegroundColor Red
  }
} catch {}

# 每天最多查一次 GitHub 上的 VERSION，若有新版提醒學員更新；同時回報目前版本（失敗靜默）
try {
  $localVerFile = Join-Path $PSScriptRoot 'VERSION'
  $stampFile = Join-Path $HOME '.claude\.agent-md-starter-last-check'
  $due = (-not (Test-Path -LiteralPath $stampFile)) -or (((Get-Date) - (Get-Item -LiteralPath $stampFile).LastWriteTime).TotalHours -ge 24)
  if ($due -and (Test-Path -LiteralPath $localVerFile)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $stampFile) | Out-Null
    Set-Content -LiteralPath $stampFile -Value (Get-Date -Format s) -NoNewline
    $localVer = (Get-Content -LiteralPath $localVerFile -Raw).Trim()
    $remoteVer = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 -Uri 'https://raw.githubusercontent.com/bingo-taiwan/agent-md-starter/master/VERSION').Content.Trim()
    if ([version]$remoteVer -gt [version]$localVer) {
      Write-Host "[agent-md-starter] 有新版 v$remoteVer（目前 v$localVer）！更新：cd $PSScriptRoot; git pull; .\install.ps1" -ForegroundColor Magenta
    }
  }
} catch {}

# 增量快取：以 LastWriteTimeUtc.Ticks:Length 為簽名，未變動的 handoff.md 直接讀快取不重開檔
$cacheFile = Join-Path $Root '.handoff-cache.json'
$cacheSchema = 1
$cacheEntries = @{}
if (Test-Path -LiteralPath $cacheFile) {
  try {
    $rawCache = Get-Content -LiteralPath $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    if ($rawCache.schema_version -eq $cacheSchema -and $rawCache.entries) {
      foreach ($p in $rawCache.entries.PSObject.Properties) { $cacheEntries[$p.Name] = $p.Value }
    }
  } catch {}
}
$newCache = @{}
$cacheDirty = $false

$items = @(Get-ChildItem -Path $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $h = Join-Path $_.FullName 'docs\handoff.md'
  $fi = Get-Item -LiteralPath $h -ErrorAction SilentlyContinue
  if ($fi) {
    $sig = "$($fi.LastWriteTimeUtc.Ticks):$($fi.Length)"
    $ce = $cacheEntries[$h]
    if ($ce -and ([string]$ce.sig -eq $sig)) {
      $updated = [string]$ce.updated
      $status  = [string]$ce.status
    } else {
      try {
        $txt = Get-Content -LiteralPath $h -Raw -Encoding UTF8 -ErrorAction Stop
        $updated = if ($txt -match '(?m)^updated:\s*(.+)$') { $Matches[1].Trim() } else { '' }
        $status  = if ($txt -match '(?s)## 目前狀態\s*\r?\n-\s*([^\r\n]+)') { $Matches[1].Trim() } else { '' }
        $cacheDirty = $true
      } catch {
        Write-Host "  [!] 無法讀取 $h（權限被鎖定）：$($_.Exception.Message)" -ForegroundColor Yellow
        return
      }
    }
    $newCache[$h] = @{ sig = $sig; updated = $updated; status = $status }
    [pscustomobject]@{ Name = $_.Name; Dir = $_.FullName; Updated = $updated; Status = $status }
  }
} | Sort-Object Updated -Descending)

if ($cacheDirty -or ($newCache.Count -ne $cacheEntries.Count)) {
  try {
    @{ schema_version = $cacheSchema; entries = $newCache } |
      ConvertTo-Json -Depth 4 -Compress | Set-Content -LiteralPath $cacheFile -Encoding UTF8
  } catch {}
}

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