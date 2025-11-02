param(
    [switch]$Quiet,
    [switch]$AddRewriteRule
)

$ErrorActionPreference = 'Stop'
function Info($m){ if(-not $Quiet){ Write-Host "[INFO] $m" -ForegroundColor Cyan } }
function Warn($m){ if(-not $Quiet){ Write-Host "[WARN] $m" -ForegroundColor Yellow } }
function Err ($m){ Write-Host "[ERROR] $m" -ForegroundColor Red }

try { $repoRoot = git rev-parse --show-toplevel 2>$null } catch { $repoRoot = $null }
if ($repoRoot) { Set-Location $repoRoot; Info "Repo root: $repoRoot" }

# Optionally add a rewrite so https://github.com/ becomes git@github.com:
if ($AddRewriteRule) {
    Info "Adding global rewrite: url.git@github.com:.insteadof https://github.com/"
    git config --global url.git@github.com:.insteadof https://github.com/
} else {
    Info "Keeping global config unchanged (no rewrite added)."
}

# Prefer SSH for gh
try {
    gh config set git_protocol ssh 2>$null
    Info "gh git_protocol set to ssh"
} catch { Warn "gh not available or config set failed; continuing" }

# Ensure origin uses SSH
$script = Join-Path $PSScriptRoot 'git-remote-to-ssh.ps1'
if (Test-Path $script) {
    & $script -Quiet
} else {
    Warn "Helper $script missing; falling back to git remote set-url"
    try {
        $nwo = gh repo view --json nameWithOwner -q .nameWithOwner 2>$null
    } catch { $nwo = $null }
    if ($nwo) {
        $owner,$repo = $nwo.Trim().Split('/')
        $url = "git@github.com:$owner/$repo.git"
        git remote set-url origin $url
    }
}

# Check SSH key presence
try {
    $keys = Get-ChildItem -Path "$HOME/.ssh" -Filter "*.pub" -File -ErrorAction SilentlyContinue
    if (-not $keys) {
        Warn "No SSH public keys found under $HOME/.ssh. Generate one and add to GitHub: https://github.com/settings/keys"
        Write-Host "  ssh-keygen -t ed25519 -C \"you@example.com\"" -ForegroundColor DarkGray
        Write-Host "  Get-Content $HOME/.ssh/id_ed25519.pub | Set-Clipboard" -ForegroundColor DarkGray
        Write-Host "  ssh -T git@github.com" -ForegroundColor DarkGray
    }
} catch { }

Info "Current remotes:"
 git remote -v | ForEach-Object { Write-Host "  $_" }

Info "SSH preference applied. You can now push via SSH (if keys are configured)."
