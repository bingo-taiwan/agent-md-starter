# 把 AGENTS.md 裝成三個 CLI 的全域指令，另裝 handoff 與「收工」skill、Claude hook、桌面捷徑。
# 檔案為 UTF-8 with BOM，Windows PowerShell 5.1 才能正確讀中文。
# 用法：powershell -ExecutionPolicy Bypass -File .\install.ps1 [-SkipPermissions]
#   -SkipPermissions：另建一個明確標示的捷徑，agent 以 --dangerously-skip-permissions 啟動（自動放行所有工具）。
#   預設不建，一般捷徑啟動的 agent 會照常詢問權限。
param([switch]$SkipPermissions)
$verFile = Join-Path $PSScriptRoot 'VERSION'
$Version = if (Test-Path -LiteralPath $verFile) { (Get-Content -LiteralPath $verFile -Raw).Trim() } else { '1.0.0' }
$gitSha  = try { (git -C $PSScriptRoot rev-parse --short HEAD 2>$null).Trim() } catch { '' }
$verTag  = if ($gitSha) { "$Version ($gitSha)" } else { $Version }

$src = Join-Path $PSScriptRoot 'AGENTS.md'
$targets = @(
  (Join-Path $HOME '.claude\CLAUDE.md'),
  (Join-Path $HOME '.gemini\GEMINI.md'),
  (Join-Path $HOME '.copilot\copilot-instructions.md')
)
foreach ($t in $targets) {
  New-Item -ItemType Directory -Force -Path (Split-Path $t) | Out-Null
  $harnessBlock = $null
  if (Test-Path -LiteralPath $t) {
    Copy-Item -LiteralPath $t -Destination "$t.bak" -Force
    $oldContent = Get-Content -LiteralPath $t -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($oldContent -and ($oldContent -match '(?s)(<!-- agy-harness:begin v[0-9.]+ -->.*?<!-- agy-harness:end -->)')) {
      $harnessBlock = $Matches[1]
    }
  }
  Copy-Item -LiteralPath $src -Destination $t -Force
  if ($harnessBlock) {
    $newContent = Get-Content -LiteralPath $t -Raw -Encoding UTF8
    if ($newContent -notlike '*<!-- agy-harness:begin*') {
      Add-Content -LiteralPath $t -Value ("`n" + $harnessBlock) -Encoding UTF8
    }
  }
  Write-Host "installed -> $t"
}
Set-Content -LiteralPath (Join-Path $HOME '.claude\agent-md-starter.version') -Value $verTag -Encoding UTF8 -NoNewline

# skills：Claude Code 讀 ~/.claude/skills/<name>/，Antigravity CLI (agy) 讀 ~/.gemini/config/skills/<name>/
foreach ($skill in @('handoff', '收工')) {
  $skillSrc = Join-Path $PSScriptRoot "skills\$skill"
  foreach ($d in @((Join-Path $HOME ".claude\skills\$skill"), (Join-Path $HOME ".gemini\config\skills\$skill"))) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    Copy-Item (Join-Path $skillSrc '*') $d -Recurse -Force
    Write-Host "installed -> $d"
  }
}

# Claude Code SessionStart hook（只放腳本；hooks\claude-settings-snippet.json 請自行合併進 ~/.claude/settings.json）
$hookDir = Join-Path $HOME '.claude\hooks'
New-Item -ItemType Directory -Force -Path $hookDir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'hooks\handoff-loader.sh') $hookDir -Force
Write-Host "installed -> $hookDir\handoff-loader.sh  (SessionStart hook 設定見 hooks\claude-settings-snippet.json)"

# 桌面捷徑：雙擊 -> 交接檔選單 -> 進專案啟動 agy
$desktop = [Environment]::GetFolderPath('Desktop')
$ws = New-Object -ComObject WScript.Shell
$launch = Join-Path $PSScriptRoot 'launch.ps1'
$shortcuts = @(@{ Name = 'Agent Launcher.lnk'; Args = "-NoExit -ExecutionPolicy Bypass -File `"$launch`"" })
if ($SkipPermissions) {
  $shortcuts += @{ Name = 'Agent Launcher (skip permissions).lnk'; Args = "-NoExit -ExecutionPolicy Bypass -File `"$launch`" -SkipPermissions" }
}
foreach ($s in $shortcuts) {
  $lnk = Join-Path $desktop $s.Name
  $sc = $ws.CreateShortcut($lnk)
  $sc.TargetPath = 'powershell.exe'
  $sc.Arguments = $s.Args
  $sc.WorkingDirectory = $HOME
  $sc.Save()
  Write-Host "shortcut -> $lnk"
}

# 版本安裝回報（供講者統計學員目前安裝的版本以便通知更新；失敗靜默）
try {
  $ghUser   = try { (gh api user --jq .login 2>$null | Out-String).Trim() } catch { '' }
  $gitName  = try { (git config --global user.name 2>$null | Out-String).Trim() } catch { '' }
  $gitEmail = try { (git config --global user.email 2>$null | Out-String).Trim() } catch { '' }
  $payload  = @{
    repo      = 'agent-md-starter'
    version   = $verTag
    action    = 'install'
    github    = $ghUser
    git_name  = $gitName
    git_email = $gitEmail
    host      = [string]$env:COMPUTERNAME
    user      = [string]$env:USERNAME
    os        = [string][Environment]::OSVersion.VersionString
    ci        = [string]$env:GITHUB_ACTIONS
  } | ConvertTo-Json -Compress
  Invoke-RestMethod -Uri 'https://dev.mynet.com.tw/linebot/repo_ping.php' -Method Post -ContentType 'application/json; charset=utf-8' -Body $payload -TimeoutSec 3 -ErrorAction SilentlyContinue | Out-Null
} catch {}