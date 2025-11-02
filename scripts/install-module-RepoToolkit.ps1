param(
  [string]$Version = '0.1.0',
  [switch]$Force
)
$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

# Determine user module path for PowerShell 7
$docs    = [Environment]::GetFolderPath('MyDocuments')
$modBase = Join-Path $docs 'PowerShell\Modules'
$dest    = Join-Path (Join-Path $modBase 'RepoToolkit') $Version
$destScripts = Join-Path $dest 'Scripts'

# Source module from repo
$repoModuleRoot = Join-Path $PSScriptRoot '..\modules\RepoToolkit'
$repoScripts    = Join-Path $PSScriptRoot '.'

# Create folders
New-Item -Path $destScripts -ItemType Directory -Force | Out-Null

# Copy module files
Copy-Item -LiteralPath (Join-Path $repoModuleRoot 'RepoToolkit.psm1') -Destination $dest -Force
Copy-Item -LiteralPath (Join-Path $repoModuleRoot 'RepoToolkit.psd1') -Destination $dest -Force

# Copy toolkit scripts used by module functions
$toolkitScripts = @(
  'gh-bootstrap.ps1',
  'gh-diagnostics.ps1',
  'gh-login-token.ps1',
  'repo-create-and-push.ps1',
  'git-remote-to-https.ps1',
  'git-remote-to-ssh.ps1',
  'git-prefer-https.ps1',
  'git-prefer-ssh.ps1',
  'install-global-gh-toolkit.ps1'
)
foreach ($s in $toolkitScripts) {
  $src = Join-Path $repoScripts $s
  if (Test-Path -LiteralPath $src) {
    Copy-Item -LiteralPath $src -Destination (Join-Path $destScripts $s) -Force
    Info "Installed script: $s"
  } else {
    Warn "Missing script in repo: $s"
  }
}

# Try importing the module
try {
  Import-Module (Join-Path $dest 'RepoToolkit.psd1') -Force
  $info = Get-Module RepoToolkit | Select-Object Name,Version,ModuleBase
  Info ("Installed Module: {0} {1} at {2}" -f $info.Name,$info.Version,$info.ModuleBase)
} catch {
  Warn "Module import failed. You may need to adjust PSModulePath or restart VS Code."
  throw
}
