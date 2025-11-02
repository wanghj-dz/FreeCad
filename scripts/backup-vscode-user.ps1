param(
  [string]$OutDir
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }

$codeUser = Join-Path $env:APPDATA 'Code\User'
if (-not (Test-Path -LiteralPath $codeUser)) { throw "VS Code user folder not found: $codeUser" }
$toolkit = Join-Path $env:USERPROFILE '.vscode-gh-toolkit'
$backupRoot = if ($OutDir) { $OutDir } else { Join-Path $toolkit 'backups' }
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$work = Join-Path $backupRoot ("vscode-user-$ts")
New-Item -ItemType Directory -Path $work -Force | Out-Null

# Copy key files
$files = @('settings.json','keybindings.json','tasks.json','snippets')
foreach ($f in $files) {
  $src = Join-Path $codeUser $f
  if (Test-Path -LiteralPath $src) {
    Copy-Item -LiteralPath $src -Destination (Join-Path $work $f) -Recurse -Force
  }
}

# Export installed extensions list
try {
  $extFile = Join-Path $work 'extensions.txt'
  code --list-extensions | Set-Content -LiteralPath $extFile -Encoding UTF8
} catch { Warn "Failed to export extensions list via 'code --list-extensions'" }

# Save toolkit user snippet
try {
  $toolTasks = Join-Path $toolkit 'tasks.user.json'
  if (Test-Path -LiteralPath $toolTasks) { Copy-Item -LiteralPath $toolTasks -Destination (Join-Path $work 'tasks.user.json') -Force }
} catch {}

# Zip it
$zip = Join-Path $backupRoot ("vscode-user-$ts.zip")
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $work '*') -DestinationPath $zip

Info "Backup created: $zip"
