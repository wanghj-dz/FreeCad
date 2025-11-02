param(
  [switch]$InstallExtensions
)
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }

$toolkitScripts = Join-Path $env:USERPROFILE '.vscode-gh-toolkit\scripts'
if (-not (Test-Path -LiteralPath $toolkitScripts)) {
  New-Item -ItemType Directory -Path $toolkitScripts -Force | Out-Null
}

# 1) Re-install global toolkit tasks (idempotent)
$installToolkit = Join-Path $toolkitScripts 'install-global-gh-toolkit.ps1'
if (-not (Test-Path -LiteralPath $installToolkit)) {
  # Try to find it in current workspace as a fallback
  $wsInstall = Join-Path (Get-Location) 'scripts\install-global-gh-toolkit.ps1'
  if (Test-Path -LiteralPath $wsInstall) { Copy-Item -LiteralPath $wsInstall -Destination $installToolkit -Force }
}
if (Test-Path -LiteralPath $installToolkit) {
  pwsh -NoProfile -ExecutionPolicy Bypass -File $installToolkit | Out-Host
} else {
  Warn "install-global-gh-toolkit.ps1 not found. Open your repo with scripts and run its installer once."
}

# 2) Re-install RepoToolkit module (idempotent)
$installModule = Join-Path (Get-Location) 'scripts\install-module-RepoToolkit.ps1'
if (Test-Path -LiteralPath $installModule) {
  pwsh -NoProfile -ExecutionPolicy Bypass -File $installModule | Out-Host
} else {
  Warn "install-module-RepoToolkit.ps1 not found in current folder. Open your repo folder and run it once (or copy it into $toolkitScripts)."
}

# 3) Merge user tasks from toolkit snippet
$merge = Join-Path (Get-Location) 'scripts\merge-user-tasks.ps1'
if (Test-Path -LiteralPath $merge) {
  pwsh -NoProfile -ExecutionPolicy Bypass -File $merge | Out-Host
} else {
  Warn "merge-user-tasks.ps1 not found in current folder. Use the installer task or copy the file in."
}

# 4) Optionally install extensions from latest backup
if ($InstallExtensions) {
  $restore = Join-Path (Get-Location) 'scripts\restore-vscode-user.ps1'
  if (Test-Path -LiteralPath $restore) {
    pwsh -NoProfile -ExecutionPolicy Bypass -File $restore -InstallExtensions | Out-Host
  } else {
    Warn "restore-vscode-user.ps1 not found; skip extensions install."
  }
}

Info "Bootstrap after reinstall completed. Reload VS Code to see tasks."
