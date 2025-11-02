param()
$ErrorActionPreference = 'Stop'
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$ts = Get-Date -Format 'yyyyMMddHHmmss'
$demoDir = Join-Path 'D:\' ("rt-demo-$ts")
Info "Creating demo directory: $demoDir"
New-Item -ItemType Directory -Path $demoDir | Out-Null
Set-Location $demoDir
Info "Initializing git repository"
git init | Out-Null
"Demo repo created at $demoDir" | Set-Content README.md
git add -A
git commit -m "Initial demo commit" | Out-Null

Info "Importing RepoToolkit module"
Import-Module RepoToolkit -ErrorAction Stop

Info "Invoking module script repo-create-and-push.ps1 directly (safest)"
$moduleBase = (Get-Module RepoToolkit).ModuleBase
$moduleScript = Join-Path $moduleBase 'Scripts\repo-create-and-push.ps1'
if (-not (Test-Path $moduleScript)) { throw "Module script not found: $moduleScript" }
& $moduleScript -Visibility public -UseHttps -NoPrompt

Info "Remotes:"
git remote -v

Info "Querying GH for repo info"
try {
  $info = gh repo view --json name,visibility,url -q '.name + " " + .visibility + " " + .url'
  Write-Host $info
} catch {
  Write-Warning "gh repo view failed: $_"
}

Write-Host "[INFO] Demo complete at: $demoDir"
