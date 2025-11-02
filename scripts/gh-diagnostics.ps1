param(
  [string]$OutDir = (Join-Path $PSScriptRoot '..' '.logs')
)
$ErrorActionPreference = 'SilentlyContinue'

# Ensure output directory exists
if (-not (Test-Path -LiteralPath $OutDir)) {
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$LogPath = Join-Path $OutDir "gh-diagnostics-$ts.txt"

function Write-Line([string]$s) {
  $s | Out-File -FilePath $LogPath -Encoding UTF8 -Append
}
function Write-Section([string]$title) {
  Write-Line ("`n===== $title =====")
}
function Capture($scriptBlock) {
  try { & $scriptBlock 2>&1 | Out-String } catch { $_.ToString() }
}

# Header
Write-Line ("GitHub CLI Diagnostics - $(Get-Date -Format 'u')")

# System
Write-Section 'System'
Write-Line ("OS: " + [System.Environment]::OSVersion.VersionString)
Write-Line ("PSVersion: " + $PSVersionTable.PSVersion.ToString())
Write-Line ("Shell: pwsh.exe")
Write-Line ("Workspace: " + (Get-Location).Path)

# Env
Write-Section 'Environment'
Write-Line ("PATH: " + $env:Path)
Write-Line ("HTTP_PROXY: " + ($env:HTTP_PROXY ?? ''))
Write-Line ("HTTPS_PROXY: " + ($env:HTTPS_PROXY ?? ''))
Write-Line ("NO_PROXY: " + ($env:NO_PROXY ?? ''))

# gh
Write-Section 'gh'
Write-Line (Capture { gh --version })
Write-Line (Capture { gh auth status })
Write-Line (Capture { gh config list })
Write-Line (Capture { gh api --method GET graphql -F query='{ viewer { login } }' })

# git
Write-Section 'git'
Write-Line (Capture { git --version })
Write-Line (Capture { git rev-parse --is-inside-work-tree })
Write-Line (Capture { git remote -v })
Write-Line (Capture { git config --list --show-origin })

Write-Line ("`nSaved log: $LogPath")
Write-Host "Diagnostics written to: $LogPath"
