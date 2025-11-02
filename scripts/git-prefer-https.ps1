param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
function Info($m){ if(-not $Quiet){ Write-Host "[INFO] $m" -ForegroundColor Cyan } }
function Warn($m){ if(-not $Quiet){ Write-Host "[WARN] $m" -ForegroundColor Yellow } }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

try { $repoRoot = git rev-parse --show-toplevel 2>$null } catch { $repoRoot = $null }
if ($repoRoot) { Set-Location $repoRoot; Info "Repo root: $repoRoot" }

# Remove HTTPS->SSH rewrite if present
$rule = 'url.git@github.com:.insteadof'
$match = git config --show-origin --get-regexp "^$rule$" 2>$null
if ($LASTEXITCODE -eq 0 -and $match) {
    Info "Removing global rewrite: $rule https://github.com/"
    git config --global --unset $rule "https://github.com/" 2>$null
}
# Also try local unset just in case
try { git config --local --unset $rule "https://github.com/" 2>$null } catch {}

# Prefer HTTPS for gh as well
try {
    gh config set git_protocol https 2>$null
    Info "gh git_protocol set to https"
} catch { Warn "gh not available or config set failed; continuing" }

# Ensure origin uses HTTPS
$script = Join-Path $PSScriptRoot 'git-remote-to-https.ps1'
if (Test-Path $script) {
    & $script -Quiet
} else {
    Warn "Helper $script missing; falling back to git remote set-url"
    # Try to infer owner/repo from gh, else keep existing origin but set to https
    try {
        $nwo = gh repo view --json nameWithOwner -q .nameWithOwner 2>$null
    } catch { $nwo = $null }
    if ($nwo) {
        $owner,$repo = $nwo.Trim().Split('/')
        $url = "https://github.com/$owner/$repo.git"
        git remote set-url origin $url
    }
}

# Show remotes
Info "Current remotes:"
 git remote -v | ForEach-Object { Write-Host "  $_" }

Info "Done. You can now push via HTTPS."
