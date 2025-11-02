param(
  [string]$ZipPath,
  [switch]$InstallExtensions,
  [switch]$MergeTasks
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }

$codeUser = Join-Path $env:APPDATA 'Code\User'
New-Item -ItemType Directory -Path $codeUser -Force | Out-Null

if (-not $ZipPath) {
  # pick latest backup from toolkit backups folder
  $backups = Get-ChildItem -Path (Join-Path $env:USERPROFILE '.vscode-gh-toolkit\backups') -Filter 'vscode-user-*.zip' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if (-not $backups) { throw 'No backup zip found. Provide -ZipPath' }
  $ZipPath = $backups[0].FullName
}
if (-not (Test-Path -LiteralPath $ZipPath)) { throw "Zip not found: $ZipPath" }

$extractDir = Join-Path $env:TEMP ("restore-" + [IO.Path]::GetFileNameWithoutExtension($ZipPath))
if (Test-Path -LiteralPath $extractDir) { Remove-Item -Recurse -Force -LiteralPath $extractDir }
New-Item -ItemType Directory -Path $extractDir | Out-Null
Expand-Archive -Path $ZipPath -DestinationPath $extractDir -Force

# The archive contains settings.json, keybindings.json, tasks.json, snippets/, tasks.user.json, extensions.txt
$src = $extractDir

# Restore settings and keybindings
foreach ($f in @('settings.json','keybindings.json')) {
  $from = Join-Path $src $f
  if (Test-Path -LiteralPath $from) {
    Copy-Item -LiteralPath $from -Destination (Join-Path $codeUser $f) -Force
  }
}

# Restore tasks.json: either merge or overwrite
$fromTasks = Join-Path $src 'tasks.json'
if (Test-Path -LiteralPath $fromTasks) {
  if ($MergeTasks) {
    try {
      $userTasks = Join-Path $codeUser 'tasks.json'
      if (-not (Test-Path -LiteralPath $userTasks)) {
        Copy-Item -LiteralPath $fromTasks -Destination $userTasks
      } else {
        $u = Get-Content -LiteralPath $userTasks -Raw | ConvertFrom-Json
        $s = Get-Content -LiteralPath $fromTasks -Raw | ConvertFrom-Json
        if (-not $u.PSObject.Properties.Name.Contains('tasks')) { $u | Add-Member -NotePropertyName tasks -NotePropertyValue @() }
        $labels = @{}
        foreach ($t in ($u.tasks | Where-Object { $_ -and $_.label })) { $labels[$t.label] = $true }
        foreach ($t in ($s.tasks | Where-Object { $_ -and $_.label })) { if (-not $labels.ContainsKey($t.label)) { $u.tasks += $t; $labels[$t.label] = $true } }
        $u | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $userTasks -Encoding UTF8
      }
    } catch { Warn "Failed to merge tasks.json. Overwrite manually if needed." }
  } else {
    Copy-Item -LiteralPath $fromTasks -Destination (Join-Path $codeUser 'tasks.json') -Force
  }
}

# Restore snippets folder content
$snippets = Join-Path $src 'snippets'
if (Test-Path -LiteralPath $snippets) {
  Copy-Item -LiteralPath (Join-Path $snippets '*') -Destination (Join-Path $codeUser 'snippets') -Recurse -Force -ErrorAction SilentlyContinue
}

# Optionally install extensions
if ($InstallExtensions) {
  $extFile = Join-Path $src 'extensions.txt'
  if (Test-Path -LiteralPath $extFile) {
    Get-Content -LiteralPath $extFile | ForEach-Object { if ($_ -and ($_ -notmatch '^\s*$')) { code --install-extension $_ } }
  }
}

Info "Restore finished. You may need to reload VS Code."
